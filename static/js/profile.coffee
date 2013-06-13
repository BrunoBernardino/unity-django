$(document).ready ->
	$('select[name="timezone"]').chosen
		search_contains: true

	# Update Profile
	$(document).on 'submit.unity', 'section.user-profile form', (event) ->
		event.preventDefault()
		window.unityApp.startLoading()

		formElement = event.target

		$.ajax '/ajax/profile',
			data:
				first_name: $(formElement).find('input[name="first_name"]').val()
				last_name: $(formElement).find('input[name="last_name"]').val()
				current_password: $(formElement).find('input[name="current_password"]').val()
				new_password: $(formElement).find('input[name="new_password"]').val()
				email: $(formElement).find('input[name="email"]').val()
				url: $(formElement).find('input[name="url"]').val()
				phone: $(formElement).find('input[name="phone"]').val()
				remove_avatar: $(formElement).find('input[name="remove_avatar"]').prop('checked')
			dataType: 'json'
			type: 'POST'

			success: (response) ->
				if !response || response.error
					window.unityApp.stopLoading()
					window.unityApp.showError( response.msg )
				else
					if $(formElement).find('input[name="avatar"]').val()
						# Do avatar upload now that we have updated everything else
						$.ajax '/ajax/profile',
							files: $(formElement).find('input[name="avatar"]')
							iframe: true
							dataType: 'json'

							success: (response) ->
								if !response || response.error
									window.unityApp.stopLoading()
									window.unityApp.showError( response.msg )
								else
									window.location.reload()
								true

							error: (jqXHR, textStatus, errorThrown) ->
								window.unityApp.stopLoading()
								window.unityApp.showError( window.unityApp.i18n.error.message )
								false
					else
						window.location.reload()

				true

			error: (jqXHR, textStatus, errorThrown) ->
				window.unityApp.stopLoading()
				window.unityApp.showError( window.unityApp.i18n.error.message )
				false

		false

	false