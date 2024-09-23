
using Pipe: @pipe

square(x)=x*x

(
	[2,4,5,2] 
	.|> square 
)
#%%
multiply(x, y) = (x * y, x * y*2)

square(x::Tuple)=x.*x

result = @pipe (2, 3) |> multiply(_...) |> square

