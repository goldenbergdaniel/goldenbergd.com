package main

import "core:fmt"
import "core:slice"
import "core:strings"
import os "core:os/os2"
import "core:path/filepath"

COPYRIGHT :: "2024-2025"

PATH_TO_INPUT  :: "content/"
PATH_TO_OUTPUT :: "pages/posts/"

main :: proc()
{
  context.allocator = context.temp_allocator
  defer free_all(context.temp_allocator)

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

  post_files, posts_rd_err := os.read_all_directory_by_path(PATH_TO_INPUT, context.allocator)
  if posts_rd_err != nil
  {
    fmt.eprintln("Error reading content directory!", posts_rd_err)
    os.exit(1)
  }

  // - Sort posts by date ---
  {
    parser: MD_Parser
    parser.data = {}
    
    slice.sort_by(post_files, proc(i, j: os.File_Info) -> bool {
      return strings.compare(i.name, j.name) == -1
    })
  }

  file_idx: int
  for file_info in post_files
  {
    if len(file_info.name) < 4 do continue
    if strings.compare(file_info.name[len(file_info.name)-3:], ".md") != 0 do continue

    output_builder := strings.builder_make(context.allocator)
    content_entry_name := file_info.name[:len(file_info.name)-3]
    defer file_idx += 1

    // - Read file and write output ---
    {
      path_to_file := strings.concatenate({PATH_TO_INPUT, file_info.name}) 
      content_fd, content_open_err := os.open(path_to_file, {.Read})
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
      content_idx := fmt.tprintf("%i", file_idx)

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
            strings.write_string(&output_builder, content_idx)
          case "copyright": 
            strings.write_string(&output_builder, COPYRIGHT)
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
              }
            }
          }

          idx += placeholder_len
        }
      }
    }

    // - Dump output to file ---
    {
      output_dir_path := strings.concatenate({PATH_TO_OUTPUT, content_entry_name, "/"})
      os.make_directory("output/")
      os.make_directory(output_dir_path)
      
      output_path := strings.concatenate({output_dir_path, "index.html"})
      output_open_flags := os.File_Flags{.Create, .Trunc, .Read, .Write}
      output_fd, output_open_err := os.open(output_path, output_open_flags, 0o644)
      defer os.close(output_fd)
      if output_open_err != nil
      {
        fmt.eprintln("Error opening output file!", output_open_err)
        os.exit(1)
      }

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

write_heading :: proc(builder: ^strings.Builder, content: string)
{
  strings.write_string(builder, "      <h2 id=\"")
  strings.write_string(builder, hyphenate_string(content))
  strings.write_string(builder, "\">")
  strings.write_string(builder, content)
  strings.write_string(builder, " <a href=\"")
  strings.write_string(builder, hyphenate_string(content))
  strings.write_string(builder, "\">#</a></h2>\n")
}

write_paragraph :: proc(builder: ^strings.Builder, content: string)
{
  strings.write_string(builder, "      <p>")

  for idx := 0; idx < len(content); idx += 1
  {
    token_len: int

    if content[idx] == '`'
    {
      // - Code ---
      idx += 1
      token_len = strings.index_byte(string(content[idx:]), '`')
      strings.write_string(builder, "<code class=\"inline-code\">")
      strings.write_string(builder, content[idx:idx+token_len])
      strings.write_string(builder, "</code>")
    }
    else if len(content[idx:]) > 2 && strings.compare(content[idx:idx+3], "***") == 0
    {
      // - Italic bold ---
      idx += 3
      token_len = strings.index_byte(string(content[idx:]), '*')
      strings.write_string(builder, "<strong><em>")
      strings.write_string(builder, content[idx:idx+token_len])
      strings.write_string(builder, "</em></strong>")
      idx += 2
    }
    else if len(content[idx:]) > 1 && strings.compare(content[idx:idx+2], "**") == 0
    {
      // - Bold ---
      idx += 2
      token_len = strings.index_byte(string(content[idx:]), '*')
      strings.write_string(builder, "<strong>")
      strings.write_string(builder, content[idx:idx+token_len])
      strings.write_string(builder, "</strong>")
      idx += 1
    }
    else if content[idx] == '*'
    {
      // - Italic ---
      idx += 1
      token_len = strings.index_byte(string(content[idx:]), '*')
      strings.write_string(builder, "<em>")
      strings.write_string(builder, content[idx:idx+token_len])
      strings.write_string(builder, "</em>")
    }
    else
    {
      strings.write_byte(builder, content[idx])
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
  COPYRIGHT,
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
