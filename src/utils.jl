clearline() = print("\033[1\033[G\033[2K")

set_terminal_title(title::String) = print(IOContext(stdout, :color => true), "\e]0;$title\a")