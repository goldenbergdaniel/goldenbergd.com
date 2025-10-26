package generator

import "core:fmt"
import vmem "core:mem/virtual"
import "core:strings"
import os "core:os/os2"
import toml "core:encoding/ini"

Config :: struct
{
  content_path: string,
  output_path:  string,
  copyright:    string,
}

main :: proc()
{
  arena: vmem.Arena
  _ = vmem.arena_init_static(&arena)
  context.allocator = vmem.arena_allocator(&arena)

  temp_arena: vmem.Arena
  _ = vmem.arena_init_static(&temp_arena)
  context.temp_allocator = vmem.arena_allocator(&temp_arena)

  // - Read config file ---
  config: Config
  {
    cfg, err, ok := toml.load_map_from_path("config.toml", context.allocator)
    if err != nil || !ok
    {
      fmt.println("Error reading config.toml!")
      os.exit(1)
    }

    config.content_path = cfg["general"]["content_path"]
    config.output_path = cfg["general"]["output_path"]
    config.copyright = cfg["general"]["copyright"]
  }

  // - Read template.html ---
  template_data := make([]byte, 4 << 10, context.allocator)
  {
    template_fd, template_open_err := os.open("generator/template.html", {.Read})
    if template_open_err != nil
    {
      fmt.eprintln("Error opening template.html!", template_open_err)
      os.exit(1)
    }

    template_len, template_rd_err := os.read(template_fd, template_data)
    if template_rd_err != nil
    {
      fmt.eprintln("Error reading template.html!", template_rd_err)
      os.exit(1)
    }

    template_data = template_data[:template_len]
  }

  post_content_path := strings.concatenate({config.content_path, "/", "posts/"})
  post_files, posts_rd_err := os.read_all_directory_by_path(post_content_path)
  if posts_rd_err != nil
  {
    fmt.eprintln("Error reading content directory!", posts_rd_err)
    os.exit(1)
  }

  file_idx: int
  for post_file in post_files
  {
    if len(post_file.name) < 4 do continue
    if strings.compare(post_file.name[len(post_file.name)-3:], ".md") != 0 do continue

    underscore_pos := strings.index_byte(post_file.name, '_')
    if underscore_pos < 1 do continue

    post_idx := post_file.name[:underscore_pos]
    post_name := post_file.name[underscore_pos+1:len(post_file.name)-3]

    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)

    output_builder := strings.builder_make(context.allocator)

    // - Read file and write output ---
    {
      content_fd, content_open_err := os.open(post_file.fullpath, {.Read})
      defer os.close(content_fd)
      if content_open_err != nil
      {
        fmt.eprintln("Error opening content.md!", content_open_err)
        os.exit(1)
      }

      content_data := make([]byte, 8 << 10)

      content_len, posts_rd_err := os.read(content_fd, content_data)
      if content_open_err != nil
      {
        fmt.eprintln("Error reading content.md!", posts_rd_err)
        os.exit(1)
      }

      content_parser: MD_Parser
      content_parser.data = cast(string) content_data

      content_title, _ := md_read_element(&content_parser)
      content_caption, _ := md_read_element(&content_parser)
      content_date, _ := md_read_element(&content_parser)

      for idx := 0; idx < len(template_data); idx += 1
      {
        char := template_data[idx]

        if char != '{' && char != '}'
        {
          strings.write_byte(&output_builder, char)
        }

        if char == '{'
        {
          idx += 1
          placeholder_len := strings.index_byte(string(template_data[idx:]), '}')
          placeholder_name := cast(string) template_data[idx:idx+placeholder_len]
          switch placeholder_name
          {
          case "title": 
            strings.write_string(&output_builder, content_title)
          case "caption": 
            strings.write_string(&output_builder, content_caption)
          case "date": 
            strings.write_string(&output_builder, content_date)
          case "number": 
            strings.write_string(&output_builder, post_idx)
          case "copyright": 
            strings.write_string(&output_builder, config.copyright)
          case "body":
            body_loop: for
            {
              element, kind := md_read_element(&content_parser)
              #partial switch kind
              {
                case .NIL:
                  idx += 1
                  break body_loop
                case .BLANK:
                  continue body_loop
                case .HEADING: 
                  write_heading(&output_builder, element)
                case .PARAGRAPH:
                  write_paragraph(&output_builder, element)
                case .CODE_BLOCK: 
                  write_code_block(&output_builder, element)
                case .IMAGE:
                  write_image(&output_builder, element)
              }
            }
          }

          idx += placeholder_len
        }
      }
    }

    // - Dump output to file ---
    {
      post_dir_path := strings.concatenate({
        config.output_path, 
        "/",
        "posts/", 
        post_name, 
        "/",
      })
      os.make_directory_all(post_dir_path)
      
      post_file_path := strings.concatenate({post_dir_path, "index.html"})
      post_file_open_flags := os.File_Flags{.Create, .Trunc, .Read, .Write}
      output_fd, _ := os.open(post_file_path, post_file_open_flags, 0o644)
      defer os.close(output_fd)

      output_bytes := transmute([]byte) strings.to_string(output_builder)
      output_written, output_wr_err := os.write(output_fd, output_bytes)
      if output_wr_err != nil
      {
        fmt.eprintln("Error writing output file!", output_wr_err)
        os.exit(1)
      }
    }
  }
}

write_heading :: proc(builder: ^strings.Builder, data: string)
{
  strings.write_string(builder, "      <h2 id=\"")
  strings.write_string(builder, hyphenate_string(data))
  strings.write_string(builder, "\">")
  strings.write_string(builder, data)
  strings.write_string(builder, " <a href=\"#")
  strings.write_string(builder, hyphenate_string(data))
  strings.write_string(builder, "\">#</a></h2>\n")
}

write_paragraph :: proc(builder: ^strings.Builder, data: string)
{
  strings.write_string(builder, "      <p>")

  for idx := 0; idx < len(data); idx += 1
  {
    token_len: int

    inline_kind := md_inline_kind(data, idx)
    switch inline_kind
    {
    case .NIL:
      strings.write_byte(builder, data[idx])
    case .ITALIC:
      idx += 1
      token_len = strings.index_byte(string(data[idx:]), '*')
      if token_len > 0
      {
        strings.write_string(builder, "<em>")
        strings.write_string(builder, data[idx:idx+token_len])
        strings.write_string(builder, "</em>")
      }
    case .BOLD:
      idx += 2
      token_len = strings.index_byte(string(data[idx:]), '*')
      if token_len > 0
      {
        strings.write_string(builder, "<strong>")
        strings.write_string(builder, data[idx:idx+token_len])
        strings.write_string(builder, "</strong>")
        idx += 1
      }
    case .ITALIC_BOLD:
      idx += 3
      token_len = strings.index_byte(string(data[idx:]), '*')
      if token_len > 0
      {
        strings.write_string(builder, "<strong><em>")
        strings.write_string(builder, data[idx:idx+token_len])
        strings.write_string(builder, "</em></strong>")
        idx += 2
      }
    case .CODE:
      idx += 1
      token_len = strings.index_byte(string(data[idx:]), '`')
      if token_len > 0
      {
        strings.write_string(builder, "<code class=\"inline-code\">")
        strings.write_string(builder, data[idx:idx+token_len])
        strings.write_string(builder, "</code>")
      }
    case .LINK:
      idx += 1

      matched: bool
      name, link: string
      last_char := '['

      i: int
      pattern: for i = idx; i < len(data); i += 1
      {
        switch data[i]
        {
        case ']':
          if last_char == '['
          {
            last_char = ']'
            name = data[idx:i]
          }
        case '(':
          if last_char == ']'
          {
            last_char = '('
          }
          else
          {
            break pattern
          }
        case ')':
          if last_char == '('
          {
            link = data[idx+len(name)+2:i]
            matched = true
          }
          break pattern
        }
      }

      if matched
      {
        strings.write_string(builder, "<a href=\"")
        strings.write_string(builder, link)
        strings.write_string(builder, "\">")
        strings.write_string(builder, name)
        strings.write_string(builder, "</a>")

        idx = i
      }
      else
      {
        idx -= 1
        strings.write_byte(builder, '[')
      }
    }

    idx += token_len
  }

  strings.write_string(builder, "</p>\n")
}

write_code_block :: proc(builder: ^strings.Builder, content: string)
{
  strings.write_string(builder, "      <pre><code>\n")
  strings.write_string(builder, content)
  strings.write_string(builder, "      </code></pre>\n")
}

write_image :: proc(builder: ^strings.Builder, content: string)
{
  strings.write_string(builder, "      <img src=\"")

  name_end := strings.index_byte(content, ']')
  name, _ := strings.substring(content, 0, name_end)
  link, _ := strings.substring(content, name_end+2, len(content)-1)

  strings.write_string(builder, link)
  strings.write_string(builder, "\" alt=\"")
  strings.write_string(builder, name)
  strings.write_string(builder, "\"/>\n")
}

hyphenate_string :: proc(str: string, allocator := context.allocator) -> string
{
  result := make([]byte, len(str), allocator)
  result_len: int

  for char in str
  {
    if char == ' '
    {
      result[result_len] = '-'
    }
    else if char >= 'A' && char <= 'Z'
    {
      result[result_len] = cast(byte) char + 32
    }
    else
    {
      result[result_len] = cast(byte) char
    }

    result_len += 1
  }

  return cast(string) result
}

MD_Parser :: struct
{
  data: string,
  pos:  int,
}

MD_Line_Kind :: enum
{
  NIL,
  BLANK,
  TITLE,
  CAPTION,
  DATE,
  HEADING,
  PARAGRAPH,
  CODE_BLOCK,
  IMAGE,
  COPYRIGHT,
}

MD_Inline_Kind :: enum
{
  NIL,
  ITALIC,
  BOLD,
  ITALIC_BOLD,
  CODE,
  LINK,
}

md_read_element :: proc(parser: ^MD_Parser) -> (content: string, kind: MD_Line_Kind)
{
  nl_off := strings.index_byte(parser.data[parser.pos:], '\n')
  if nl_off >= 1
  {
    line := parser.data[parser.pos:parser.pos+nl_off]
    parser.pos += nl_off + 1

    if len(line) > 2 && strings.compare(line[:3], "```") == 0
    {
      end_off := strings.index_byte(parser.data[parser.pos:], '`')
      content = parser.data[parser.pos:parser.pos+end_off]
      kind = .CODE_BLOCK

      parser.pos += end_off + 3
    }
    else if len(line) > 4 && strings.compare(line[:4], "####") == 0
    {
      content = line[5:]
      kind = .DATE
    }
    else if len(line) > 3 && strings.compare(line[:3], "###") == 0
    {
      content = line[4:]
      kind = .CAPTION
    }
    else if len(line) > 2 && strings.compare(line[:2], "##") == 0
    {
      content = line[3:]
      kind = .HEADING
    }
    else if len(line) > 1 && line[0] == '#' && line[1] == ' '
    {
      content = line[2:]
      kind = .TITLE
    }
    else if len(line) > 1 && strings.compare(line[:2], "![") == 0
    {
      content = line[2:]
      kind = .IMAGE
    }
    else
    {
      content = line
      kind = .PARAGRAPH
    }
  }
  else if nl_off == 0
  {
    parser.pos += 1
    kind = .BLANK
  }

  return content, kind
}

md_inline_kind :: proc(data: string, idx: int) -> MD_Inline_Kind
{
  result: MD_Inline_Kind

  if data[idx] == '`'
  {
    result = .CODE
  }
  else if len(data[idx:]) > 2 && strings.compare(data[idx:idx+3], "***") == 0
  {
    result = .ITALIC_BOLD
  }
  else if len(data[idx:]) > 1 && strings.compare(data[idx:idx+2], "**") == 0
  {
    result = .BOLD
  }
  else if data[idx] == '*'
  {
    result = .ITALIC
  }
  else if data[idx] == '['
  {
    result = .LINK
  }

  return result
}
