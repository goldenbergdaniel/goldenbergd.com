# Odin for C Programmers
### A primer on the Odin programming language for C veterans.
#### 2025.05.16

This blog post is a rundown of some of the things a programmer familiar with C may find surprising about Odin.

## Arrays and Slices
Lets start with arrays, which in Odin are of the form `[N]T`. Just like in C, an array in Odin is a contiguous list of elements of the same type. Where Odin's array differs from C is that it does not degrade to a pointer when assigned to one. This can be observed in the following code snippets. Note that in Odin, we would generally pass an array by slice rather than by pointer. 
```
// - C ---
int array[8];
int *ptr = array; // Valid
int *ptr = &array; // Also valid
```
```
// - Odin --
array: [8]int
ptr_1: ^int = array // Error
ptr_2: ^[8]int = &array // Valid
```
A slice in Odin, of the form `[]T`, is simply a struct which contains a pointer to the first element and an integer for the number of elements it points to. It's layout in memory can be seen in the snippets below, taken directly from the [Odin runtime](https://github.com/odin-lang/Odin/blob/master/base/runtime/core.odin#L395).
```
Raw_Slice :: struct
{
	data: rawptr,
	len:  int,
}
```

## Strings
```
Raw_String :: struct
{
	data: [^]u8, // ok?
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

## Bit Sets and Bit Fields

## Inline Assembly

