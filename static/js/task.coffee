$(document).ready ->
	window.unityApp.taskCollection = new window.unityApp.TaskCollection
	window.unityApp.commentView = new CommentView el: $('#task-comments')
	window.unityApp.userView = new UserView

	window.unityApp.taskCollection.fetch
		data:
			list_id: $('#main').data 'list'
		dataType: 'json'
		type: 'GET'

	# Complete Task
	$(document).on 'click.unity', 'a.task-complete', (event) -> 
		event.preventDefault()
		window.unityApp.startLoading()

		anchorElement = event.target

		bootbox.confirm 'Are you sure you want to mark this task as complete?', (answer) ->
			if answer
				taskId = parseInt( $('#main').data('task'), 10)
				task = window.unityApp.taskCollection.get taskId
				
				taskAttributes = {
					completed: true
				}

				task.save(
					taskAttributes
					success: ->
						window.location.reload()

						true
				)
			false

		false

	# Incomplete Task
	$(document).on 'click.unity', 'a.task-incomplete', (event) -> 
		event.preventDefault()
		window.unityApp.startLoading()

		anchorElement = event.target

		bootbox.confirm 'Are you sure you want to mark this task as incomplete?', (answer) ->
			if answer
				taskId = parseInt( $('#main').data('task'), 10)
				task = window.unityApp.taskCollection.get taskId
				
				taskAttributes = {
					completed: false
				}

				task.save(
					taskAttributes
					success: ->
						window.location.reload()

						true
				)
			false

		false

	# Edit Task
	$(document).on 'click.unity', 'a.task-edit', (event) ->
		event.preventDefault()

		anchorElement = event.target

		backboneViewObject = this

		taskId = parseInt( $('#main').data('task'), 10)

		dialogData = {
			modal:
				header: 'Edit Task'
				identifier: 'tasks-edit'
			info:
				model: 'Task'
				crud: 'update'
				url: window.unityApp.taskCollection.url
			users: window.unityApp.userView.userCollection.toJSON()
			task: window.unityApp.taskCollection.get taskId
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Update Task'
		}

		window.unityApp.showDialog 'tasks-edit', dialogData, buttonData
		
		$('input[name="due_date"]').datepicker()

		false

	# Update Task button
	$(document).on 'click.unity', '.modal[data-identifier=' + Sha1.hash('tasks-edit') + '] .modal-footer .btn-primary', (event) ->
		event.preventDefault();
		$('div.dialog-form.tasks-edit form').trigger 'submit' 

		true

	# Update Task
	$(document).on 'submit.unity', 'div.dialog-form.tasks-edit form', (event) ->
		event.preventDefault()
		window.unityApp.startLoading()

		formElement = event.target

		task = window.unityApp.taskCollection.get $(formElement).data('id')

		taskAttributes = {
			title: $(formElement).find('input[name="title"]').val()
			description: $(formElement).find('textarea[name="description"]').val()
			due_date: $(formElement).find('input[name="due_date"]').val()
			priority: $(formElement).find('input[name="priority"]').val()
			responsible:
				id: $(formElement).find('select[name="responsible"]').val()
		}

		task.save(
			taskAttributes
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

		comment = new window.unityApp.TaskComment()

		commentAttributes = {
			task: 
				id: $('#main').data 'task'
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
							object: 'tc'
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
		this.commentCollection = new window.unityApp.TaskCommentCollection()
		this.render()

	events:
		'click a.edit': 'edit'
		'click a.delete': 'delete'

	render: ->
		backboneViewObject = this

		this.commentCollection.fetch
			data:
				task_id: $('#main').data 'task'
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
				model: 'TaskComment'
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

UserView = Backbone.View.extend
	initialize: ->
		this.userCollection = new window.unityApp.UserCollection()

		this.userCollection.fetch
			data:
				project_id: $('#main').data 'project'
			dataType: 'json'
			type: 'GET'