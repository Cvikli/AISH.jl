





function context_combiner!(user_question, context_shell, context_codebase)
	"""
	$(fetch(context_shell))

	$(fetch(context_codebase))

	<Question>
	$(user_question)
	</Question>
	"""
end