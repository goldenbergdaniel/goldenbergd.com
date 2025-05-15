# Odin for C Programmers
### A primer on the Odin programming language for C veterans.
#### 2025.04.14

This post is meant to be a rundown of some of the part of Odin that might feel alien to a C developer. I will update this list periodically.

## Slices and Strings
A slice in Odin, denoted by `[]T`, is simply a struct containing a pointer and an `int` for length. Here's its layout in memory, taken directly from the Odin runtime.
```
Raw_Slice :: struct
{
	data: rawptr,
	len:  int,
}

Raw_String :: struct
{
	data: [^]u8,
	len:  int,
}

Raw_Cstring :: struct
{
	data: [^]u8,
}
```

## Unions
```
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

## Bit Sets & Bit Fields

And there you have it!
