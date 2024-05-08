package ui

Widget_Handle :: distinct u64

Widget :: struct
{
	handle: Widget_Handle,

	left:  Widget_Handle,
	right: Widget_Handle,
	up:    Widget_Handle,
	down:  Widget_Handle,
}

X    X
X    X
X    X
X    X
for i in 0..<4
{
	begin_row()
	do_custom_elem()
	do_custom_elem()
	end_row()
}


X  X  X
begin_row()
do_custom_elem()
do_custom_elem()
do_custom_elem()
end_row()


X  X  X
X  X  X
X  X  X
X  X  X
for i in 0..<4
{
	begin_row()
	do_custom_elem()
	do_custom_elem()
	do_custom_elem()
	end_row()
}

X
X
X
X
begin_column()
do_button()
do_button()
do_button()
do_button()
end_column()


/*
X <-> X <-> X <
^     ^     ^  \
|     |     |   \
v     v     v    \
X <-> X <-> X <-> X
^     ^    /     /
|     |   /     /
v     v  /     /
X <-> X <------
*/
begin_row()
	push_elem()
	push_elem()
	push_elem()
end_row()

begin_row()
	push_elem()
	push_elem()
	push_elem()
	push_elem()
end_row()

begin_row()
	push_elem()
	push_elem()
end_row()
