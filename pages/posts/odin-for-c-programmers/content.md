# Odin for C Programmers
### A primer on the Odin programming language for C veterans.
#### 03.02.2025

This post is meant to be a rundown of some of the part of Odin that might feel alien to a C developer. I will update this list periodically.

```odin
package main

import "core:fmt"

main :: proc()
{
  fmt.println("Hellope!")
}
```

## Slices and Strings \# 
A slice in Odin, denoted by `[]T`, is simply a struct containing a pointer and an `int` for length. Here's its layout in memory, taken directly from the Odin runtime.
```odin
Raw_Slice :: struct
{
	data: rawptr,
	len:  int,
}
```

```odin
Raw_String :: struct
{
	data: [^]u8,
	len:  int,
}
```

```odin
Raw_Cstring :: struct
{
	data: [^]u8,
}
```

## Unions

```odin
My_Union :: union
{
  string,
  int,
  f32,
}

My_Raw_Union :: struct #raw_union
{
  str: string,
  num: int,
  flt: f32,
}
```

## Bit Sets and Bit Fields
