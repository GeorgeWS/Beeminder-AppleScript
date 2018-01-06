(*
  Use Beeminder with AppleScript! :)
  
  
  ***RUN THIS SCRIPT*** once to install it, and again whenever you want to "commit" any changes to it.
 
  This script library is ready to use as-is: no need to substitute in Beeminder credentials. It will prompt you for those when needed and save them in /usr/local/etc/beeminder-applescript/auth.txt (by default; see below) for reuse on subsequent calls.

  
   Usage (from any AppleScript file): 
  
  	-- Post 25 minutes to a writing goal:
    	tell script "Beeminder" to enter_datapoint("writing", 25, "Spent 25 minutes writing!")
	
	-- Retry sending the most recent unentered data:
	tell script "Beeminder" to resend_last_unentered_datapoint()
*)


-- This shell script is the only thing that acutally "runs" when you run this script file.
-- It will make the Script Libraries directory if it does not exist, and compile this library into a .scpt file there.
do shell script Â
	"mkdir -p ~/Library/Script\\ Libraries;" & Â
	"osacompile -o ~/Library/Script\\ Libraries/Beeminder.scpt " & quoted form of POSIX path of (path to me)


-- All data saved by this library (e.g. Beeminder credentials, failed data entires, etc.) is stored in stable_directory.
-- Modify stable_directory if you would like this data to be stored elsewhere.
property stable_directory : "/usr/local/etc/beeminder-applescript/"
property auth_filename : "auth.txt"
property unentered_data_filename : "unentered-data.txt"


-------------------------------------
-- MAIN BEEMINDER ACTIONS --
-------------------------------------
--  call these from anywhere!  --
-------------------------------------


(*
  Attempts to enter data of a given value into a given goal with a given comment.

  Upon success, displays a passive notification
  Upon failure, displays an alert, providing the option to try again immediately (e.g. after checking internet connectivity), or to save the data for later. Failed attempts saved for later are pushed to unentered_data_filename in stable_directory (by default, this is /usr/local/etc/beeminder-applescript/unentered-data.txt). Data entry will never "fail silently": a call to enter_datapoint will always result in either successfully entering data on beeminder, choosing to try again, or saving the data for a later attempt.
  
  WARNING: a number of characters in the comment will break this script, and I'm not sure what they all are. Definitely don't use backlashes, quotes of any kind, or line breaks in the comment. Stick to letters and numbers and basic punctuation if possible. 
*)
on enter_datapoint(goal, value, comment)
	set credentials to get_credentials()
	set comment_url_string to replace_text(comment, " ", "%20")
	set post_url to Â
		"https://www.beeminder.com/api/v1/users/" & (user of credentials) & Â
		"/goals/" & goal & Â
		"/datapoints.json?value=" & value & Â
		"&comment=" & comment_url_string & Â
		"&auth_token=" & (auth_token of credentials)
	set curl_command to "curl -d '' '" & post_url & "'"
	try
		do shell script curl_command
		display notification comment with title "Updated \"" & goal & "\" Beeminder Goal"
	on error
		set try_again to "Try Again Now"
		set save_for_later to "Save Update For Later"
		set choice to button returned of (display alert "Failed Beeminder Update" as critical message "Could not add the following data to the \"" & goal & "\" goal:" & return & return & "\"" & comment & "\"" buttons {save_for_later, try_again} default button try_again)
		if choice is try_again then
			enter_datapoint(goal, value, comment)
		else
			push_unentered_data(goal, value, comment)
		end if
	end try
end enter_datapoint


(*
  Retries the most recent failed attempt to enter data into Beeminder.
  
  Upon success, the data will be removed from the unentered data file; upon failure, the data will remain in the unentered data file for a later attempt.
*)
on resend_last_unentered_datapoint()
	local last_entry
	try
		set last_entry to pop_unentered_data()
	on error
		display notification "No unentered Beeminder data was found." with title "No Data to Resend"
		return
	end try
	enter_datapoint(goal of last_entry, value of last_entry, comment of last_entry)
end resend_last_unentered_datapoint


-- Promts you for your Beeminder credentials, saving and returning the user and auth_token you enter.
on set_credentials()
	set user to text returned of (display dialog "Enter your Beeminder username:" with title "Allow AppleScript to Update Beeminder" default answer "username")
	set auth_token to text returned of (display dialog "Enter your Beeminder auth token:" & return & return & "(Your auth token can be found at https://www.beeminder.com/api/v1/auth_token.json while you are logged in to Beeminder.)" with title "Allow AppleScript to Update Beeminder" default answer "abcdefg1234567")
	set auth_filepath to stable_directory & auth_filename
	
	-- Note: ">" (over)writes files and ">>" appends a line to a to fileÉ
	-- Éso this creates a new file with user on line 1 and auth_token on line 2.
	-- If an old auth file already exists, this will overwrite it.
	do shell script Â
		"mkdir -p " & quoted form of stable_directory & ";" & Â
		"echo " & user & " > " & quoted form of auth_filepath & ";" & Â
		"echo " & auth_token & " >> " & quoted form of auth_filepath
	
	return {user:user, auth_token:auth_token}
end set_credentials


(*
  Returns your saved Beeminder user and auth_token.
  
  First calls set_credentials (prompting you for your credentials and saving them) if they are not already saved.
*)
on get_credentials()
	try
		set credentials to read POSIX file (stable_directory & auth_filename)
		set user to first paragraph of credentials
		set auth_token to second paragraph of credentials
		return {user:user, auth_token:auth_token}
	on error
		return set_credentials()
	end try
end get_credentials


------------------------------
--  HELPER FUNCTIONS  --
------------------------------
-- for use inside this file --
------------------------------


-- Saves a goal, value, and comment to the unentered data file.
on push_unentered_data(goal, value, comment)
	set save_file to stable_directory & unentered_data_filename
	-- Store goal, value, & comment as a comma-separated line with the comment last so it can contain commas.
	set save_data to goal & "," & value & "," & comment
	do shell script Â
		"mkdir -p " & quoted form of stable_directory & "; " & Â
		"echo \"" & save_data & "\" >> " & quoted form of save_file
end push_unentered_data


--  *Removes* (caution!) & returns the most recently added goal, value, and comment from the unentered data file.
on pop_unentered_data()
	set save_file to stable_directory & unentered_data_filename
	
	-- Retrieve last line of unentered data file:
	set saved_lines to (read POSIX file save_file using delimiter linefeed)
	set last_line to last item of saved_lines
	
	-- Separate line into goal, value, and comment:
	set ASTID to AppleScript's text item delimiters
	set AppleScript's text item delimiters to ","
	set segments to every text item of last_line
	set goal to item 1 of segments
	set value to item 2 of segments as number
	set comment to items 3 through end of segments as string
	set AppleScript's text item delimiters to ASTID
	
	-- Delete last line of unentered data file:
	do shell script "sed -i '' -e '$d' " & quoted form of save_file
	
	return {goal:goal, value:value, comment:comment}
end pop_unentered_data


-- Replaces all occurences of find_string in a_string with replace_string.
on replace_text(a_string, find_string, replace_string)
	set ASTID to AppleScript's text item delimiters
	set AppleScript's text item delimiters to find_string
	set string_list to every text item of a_string
	set AppleScript's text item delimiters to replace_string
	set new_string to string_list as string
	set AppleScript's text item delimiters to ASTID
	return new_string
end replace_text
