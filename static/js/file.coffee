$(document).ready ->
	window.unityApp.fileCollection = new window.unityApp.FileCollection
	window.unityApp.commentView = new CommentView el: $('#file-comments')

	window.unityApp.fileCollection.fetch
		data:
			project_id: $('#main').data 'project'
		dataType: 'json'
		type: 'GET'

	# Edit File
	$(document).on 'click.unity', 'a.file-edit', (event) ->
		event.preventDefault()

		anchorElement = event.target

		backboneViewObject = this

		fileId = parseInt( $('#main').data('file'), 10)

		dialogData = {
			modal:
				header: 'Edit File'
				identifier: 'files-edit'
			info:
				model: 'File'
				crud: 'update'
				url: window.unityApp.fileCollection.url
			file: window.unityApp.fileCollection.get fileId
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Update File'
		}

		window.unityApp.showDialog 'files-edit', dialogData, buttonData

		false

	# Update File button
	$(document).on 'click.unity', '.modal[data-identifier=' + Sha1.hash('files-edit') + '] .modal-footer .btn-primary', (event) ->
		event.preventDefault();
		$('div.dialog-form.files-edit form').trigger 'submit' 

		true

	# Update File
	$(document).on 'submit.unity', 'div.dialog-form.files-edit form', (event) ->
		event.preventDefault()
		window.unityApp.startLoading()

		formElement = event.target

		file = window.unityApp.fileCollection.get $(formElement).data('id')

		fileAttributes = {
			description: $(formElement).find('textarea[name="description"]').val()
		}

		file.save(
			fileAttributes
			success: (model, response) ->
				window.location.reload()

				true
		)

		false

	# Add Comment
	$(document).on 'click.unity', 'a.comments-new', (event) -> 
		event.preventDefault()

		anchorElement = event.target

		dialogData = {
			modal:
				header: 'Create a New Comment'
				identifier: 'comments-new'
			info:
				model: 'Comment'
				crud: 'create'
				url: window.unityApp.commentView.commentCollection.url
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Create Comment'
		}

		window.unityApp.showDialog $(anchorElement).data('dialog'), dialogData, buttonData

		false

	# Save Comment button
	$(document).on 'click.unity', '.modal[data-identifier=' + Sha1.hash('comments-new') + '] .modal-footer .btn-primary', (event) ->
		event.preventDefault();
		$('div.dialog-form.comments-new form').trigger 'submit' 

		true

	# Save Comment
	$(document).on 'submit.unity', 'div.dialog-form.comments-new form', (event) ->
		event.preventDefault()
		window.unityApp.startLoading()

		formElement = event.target

		comment = new window.unityApp.FileComment()

		commentAttributes = {
			file: 
				id: $('#main').data 'file'
			content: $(formElement).find('textarea[name="content"]').val()
		}

		comment.save(
			commentAttributes
			success: (model, response) ->
				if $(formElement).find('input[name="files"]').val()
					# Do file upload now that we have the comment

					$.ajax '/ajax/files',
						data:
							project: $('#main').data 'project'
							id: comment.id
							object: 'fc'
						files: $(formElement).find('input[name="files"]')
						iframe: true
						dataType: 'json'

						success: (response) ->
							window.unityApp.stopLoading()

							if !response || response.error
								window.unityApp.showError( response.msg )
							else
								window.unityApp.commentView.render()
								window.unityApp.closeAllDialogs()
							true

						error: (jqXHR, textStatus, errorThrown) ->
							window.unityApp.stopLoading()
							window.unityApp.showError( window.unityApp.i18n.error.message )
							false
				else
					window.unityApp.commentView.render()
					window.unityApp.stopLoading()
					window.unityApp.closeAllDialogs()

				true
		)

		false

	# Update Comment button
	$(document).on 'click.unity', '.modal[data-identifier=' + Sha1.hash('comments-edit') + '] .modal-footer .btn-primary', (event) ->
		event.preventDefault();
		$('div.dialog-form.comments-edit form').trigger 'submit' 

		true

	# Update Comment
	$(document).on 'submit.unity', 'div.dialog-form.comments-edit form', (event) ->
		event.preventDefault()
		window.unityApp.startLoading()

		formElement = event.target

		comment = window.unityApp.commentView.commentCollection.get $(formElement).data('id')

		commentAttributes = {
			content: $(formElement).find('textarea[name="content"]').val()
		}

		comment.save(
			commentAttributes
			success: (model, response) ->
				window.unityApp.commentView.render()
				window.unityApp.stopLoading()
				window.unityApp.closeAllDialogs()

				true
		)

		false

	true

# Views
CommentView = Backbone.View.extend
	initialize: ->
		this.commentCollection = new window.unityApp.FileCommentCollection()
		this.render()

	events:
		'click a.edit': 'edit'
		'click a.delete': 'delete'

	render: ->
		backboneViewObject = this

		this.commentCollection.fetch
			data:
				file_id: $('#main').data 'file'
			dataType: 'json'
			type: 'GET'
			success: (collection, response) ->
				if response
					$(backboneViewObject.el).empty()

					commentViewTemplate = _.template $('#templates-backbone-comment').html(), comments: response

					$(backboneViewObject.el).append commentViewTemplate

					$('.comment .actions a').tooltip()

					$('.comment').each () ->
						parsedHTML = $(this).find('p:first').html().autoLink({ target: "_blank" })
						$(this).find('p:first').html parsedHTML
						true
				else
					window.unityApp.showError( window.unityApp.i18n.error.message )

	edit: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		commentId = parseInt( $(infoElement).data('id'), 10)

		dialogData = {
			modal:
				header: 'Edit Comment'
				identifier: 'comments-edit'
			info:
				model: 'FileComment'
				crud: 'update'
				url: window.unityApp.commentView.commentCollection.url
			comment: backboneViewObject.commentCollection.get commentId
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Update Comment'
		}

		window.unityApp.showDialog 'comments-edit', dialogData, buttonData

	delete: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		bootbox.confirm 'Are you sure you want to remove this comment? This action is irreversible!', (answer) ->
			if answer
				commentId = parseInt( $(infoElement).data('id'), 10)
				comment = backboneViewObject.commentCollection.get commentId
				
				comment.destroy
					success: ->
						backboneViewObject.render()

						true
			false

		false