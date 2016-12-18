class CustomerSearchTerm
	attr_reader :where_clause, :where_args, :order
	def initialize(search_term)
		search_term = search_term.downcase
		@where_clause = ""
		@where_clause1 = ""
		@where_args1 = {}
		@where_args = {}
		@multiple_words = false
		if search_term =~ /@/
			build_for_email_search(search_term)
		else
			build_for_name_search(search_term)
		end
	end

	private

	def build_for_name_search(search_term)
		if search_term.match(/\w+\s+\w+/)
			# Get two separate words from search_term
			word1 = search_term.match(/\w+\s+/)[0].strip
			word2 = search_term.match(/\s+\w+/)[0].strip

			# Build (first_name = first_word AND last_name = last_word)
			# OR (first_name = last_word AND last_name = first_word) 			
			@where_clause << "("
			@where_clause << case_insensitive_search(:first_name)
			@where_args[:first_name] = starts_with(word1)
			@where_clause << " AND #{case_insensitive_search(:last_name)}) OR ("
			@where_args[:last_name] = starts_with(word2)

			@where_clause << case_insensitive_search(:last_name)
			@where_args[:first_name] = starts_with(word2)
			@where_clause << " AND #{case_insensitive_search(:first_name)})"
			@where_args[:last_name] = starts_with(word1)

		else
			@where_clause << case_insensitive_search(:first_name)
			@where_args[:first_name] = starts_with(search_term)
			@where_clause << " OR #{case_insensitive_search(:last_name)}"
			@where_args[:last_name] = starts_with(search_term)
		end
		@order= "last_name asc"
	end

	def build_for_email_search(search_term)
		@where_clause << case_insensitive_search(:first_name)
		@where_args[:first_name]= starts_with(extract_name(search_term))
		@where_clause << " OR #{case_insensitive_search(:last_name)}"
		@where_args[:last_name] = starts_with(extract_name(search_term))
		@where_clause << " OR #{case_insensitive_search(:email)}"
		@where_args[:email] = search_term
		@order = "lower(email)= " + ActiveRecord::Base.connection.quote(search_term) + " desc, last_name asc"
	end
	def starts_with(search_term)
		search_term + "%"
	end

	def case_insensitive_search(field_name)
		"lower(#{field_name}) like :#{field_name}"
	end

	def extract_name(email)
		email.gsub(/@.*$/,'').gsub(/[0-9]+/,'')
	end

end
