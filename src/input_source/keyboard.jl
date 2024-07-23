function readline_improved()
	while true
		user_input = strip(readline())
		if !isempty(user_input)
			return user_input
		end
		println("Empty input. Please enter a message.")
		print("\e[36m➜ \e[0m ")  
	end
end
