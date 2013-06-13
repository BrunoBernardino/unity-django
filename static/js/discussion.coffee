$(document).ready ->
	window.unityApp.discussionCollection = new window.unityApp.DiscussionCollection
	window.unityApp.commentView = new CommentView el: $('#discussion-comments')

	window.unityApp.discussionCollection.fetch
		data:
			project_id: $('#main').data 'project'
		dataType: 'json'
		type: 'GET'

	# Complete Discussion
	$(document).on 'click', 'a.discussion-complete', (event) -> 
		event.preventDefault()

		anchorElement = event.target

		bootbox.confirm 'Are you sure you want to mark this discussion as complete?', (answer) ->
			if answer
				window.unityApp.startLoading()
				discussionId = parseInt( $('#main').data('discussion'), 10)
				discussion = window.unityApp.discussionCollection.get discussionId
				
				discussionAttributes = {
					completed: true
				}

				discussion.save(
					discussionAttributes
					success: ->
						window.location.reload()

						true
				)
			false

		false

	# Incomplete Discussion
	$(document).on 'click.unity', 'a.discussion-incomplete', (event) -> 
		event.preventDefault()

		anchorElement = event.target

		bootbox.confirm 'Are you sure you want to mark this discussion as incomplete?', (answer) ->
			if answer
				window.unityApp.startLoading()
				discussionId = parseInt( $('#main').data('discussion'), 10)
				discussion = window.unityApp.discussionCollection.get discussionId
				
				discussionAttributes = {
					completed: false
				}

				discussion.save(
					discussionAttributes
					success: ->
						window.location.reload()

						true
				)
			false

		false

	# Edit Discussion
	$(document).on 'click.unity', 'a.discussion-edit', (event) ->
		event.preventDefault()

		anchorElement = event.target

		backboneViewObject = this

		discussionId = parseInt( $('#main').data('discussion'), 10)

		dialogData = {
			modal:
				header: 'Edit Discussion'
				identifier: 'discussions-edit'
			info:
				model: 'Discussion'
				crud: 'update'
				url: window.unityApp.discussionCollection.url
			discussion: window.unityApp.discussionCollection.get discussionId
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Update Discussion'
		}

		window.unityApp.showDialog 'discussions-edit', dialogData, buttonData

		false

	# Update Discussion button
	$(document).on 'click.unity', '.modal[data-identifier=' + Sha1.hash('discussions-edit') + '] .modal-footer .btn-primary', (event) ->
		event.preventDefault();
		$('div.dialog-form.discussions-edit form').trigger 'submit' 

		true

	# Update Discussion
	$(document).on 'submit.unity', 'div.dialog-form.discussions-edit form', (event) ->
		event.preventDefault()
		window.unityApp.startLoading()

		formElement = event.target

		discussion = window.unityApp.discussionCollection.get $(formElement).data('id')

		discussionAttributes = {
			title: $(formElement).find('input[name="title"]').val()
			content: $(formElement).find('textarea[name="content"]').val()
		}

		if $(formElement).find('input[name="private"]').length
			discussionAttributes.private = $(formElement).find('input[name="private"]').prop('checked')

		discussion.save(
			discussionAttributes
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

		comment = new window.unityApp.DiscussionComment()

		commentAttributes = {
			discussion: 
				id: $('#main').data 'discussion'
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
							object: 'dc'
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
		this.commentCollection = new window.unityApp.DiscussionCommentCollection()
		this.render()

	events:
		'click a.edit': 'edit'
		'click a.delete': 'delete'

	render: ->
		backboneViewObject = this

		this.commentCollection.fetch
			data:
				discussion_id: $('#main').data 'discussion'
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
				model: 'DiscussionComment'
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
			false

		false