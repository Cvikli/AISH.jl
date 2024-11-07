
@kwdef mutable struct eew
	per::String

end
eew(;r::String) = begin
	println(r*r)
	eew(r)
end
eew(r="ko")
