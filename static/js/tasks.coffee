$(document).ready ->
	window.unityApp.projectView = new ProjectView el: $('#user-projects')

	# Add Task
	$(document).on 'click.unity', 'a.tasks-new', (event) ->
		event.preventDefault()

		anchorElement = event.target

		projectId = parseInt($(anchorElement).data('project'), 10)
		listId = parseInt($(anchorElement).data('list'), 10)

		dialogData = {
			modal:
				header: 'Create a New Task'
				identifier: 'tasks-new'
			info:
				model: 'Task'
				crud: 'create'
				url: window.unityApp.projectView.listViews[projectId].listCollection.url
				project: projectId
				list: listId
			users: window.unityApp.projectView.userViews[projectId].userCollection.toJSON()
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Create Task'
		}

		window.unityApp.showDialog $(anchorElement).data('dialog'), dialogData, buttonData

		$('input[name="due_date"]').datepicker()

		false

	# Save Task button
	$(document).on 'click.unity', '.modal[data-identifier=' + Sha1.hash('tasks-new') + '] .modal-footer .btn-primary', (event) ->
		event.preventDefault();
		$('div.dialog-form.tasks-new form').trigger 'submit' 

		true

	# Save Task
	$(document).on 'submit.unity', 'div.dialog-form.tasks-new form', (event) ->
		event.preventDefault()
		window.unityApp.startLoading()

		formElement = event.target

		projectId = parseInt($(formElement).data('project'), 10)
		listId = parseInt($(formElement).data('list'), 10)

		task = new window.unityApp.Task()

		taskAttributes = {
			list: 
				id: listId
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
				window.unityApp.projectView.listViews[projectId].taskViews[listId].render()

				if $(formElement).find('input[name="files"]').val()
					# Do file upload now that we have the task

					$.ajax '/ajax/files',
						data:
							project: projectId
							id: task.id
							object: 't'
						files: $(formElement).find('input[name="files"]')
						iframe: true
						dataType: 'json'

						success: (response) ->
							window.unityApp.stopLoading()

							if !response || response.error
								window.unityApp.showError( response.msg )
							else
								window.unityApp.projectView.listViews[projectId].taskViews[listId].render()
								window.unityApp.closeAllDialogs()
							true

						error: (jqXHR, textStatus, errorThrown) ->
							window.unityApp.stopLoading()
							window.unityApp.showError( window.unityApp.i18n.error.message )
							false
				else
					window.unityApp.stopLoading()
					window.unityApp.closeAllDialogs()

				true
		)

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

		projectId = parseInt($(formElement).data('project'), 10)
		listId = parseInt($(formElement).data('list'), 10)

		task = window.unityApp.projectView.listViews[projectId].taskViews[listId].taskCollection.get $(formElement).data('id')

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
				window.unityApp.projectView.listViews[projectId].taskViews[listId].render()
				window.unityApp.stopLoading()
				window.unityApp.closeAllDialogs()

				true
		)

		false

	true

# Views
ProjectView = Backbone.View.extend
	initialize: ->
		this.projectCollection = new window.unityApp.ProjectCollection()
		this.listViews = []
		this.userViews = []
		this.render()

	render: ->
		backboneViewObject = this

		this.projectCollection.fetch
			dataType: 'json'
			type: 'GET'
			success: (collection, response) ->
				if response
					$(backboneViewObject.el).empty()

					projectViewTemplate = _.template $('#templates-backbone-projects').html(), projects: response

					$(backboneViewObject.el).append projectViewTemplate

					for project in response
						listViewTemplate = new ListView el: $('.user-project-lists[data-project="' + project.id + '"]')
						backboneViewObject.listViews[project.id] = listViewTemplate

						userViewTemplate = new UserView el: $('.user-project-lists[data-project="' + project.id + '"]')
						backboneViewObject.userViews[project.id] = userViewTemplate
				else
					window.unityApp.showError( window.unityApp.i18n.error.message )

ListView = Backbone.View.extend
	initialize: ->
		this.listCollection = new window.unityApp.ListCollection()
		this.projectId = parseInt( $(this.el).data('project'), 10)
		this.taskViews = []
		this.render()

	render: ->
		backboneViewObject = this

		this.listCollection.fetch
			data:
				project_id: backboneViewObject.projectId
				incompleted_only: true
			dataType: 'json'
			type: 'GET'
			success: (collection, response) ->
				if response
					$(backboneViewObject.el).empty()

					listViewTemplate = _.template $('#templates-backbone-lists').html(), lists: response

					$(backboneViewObject.el).append listViewTemplate

					for list in response
						taskViewTemplate = new TaskView
							el: $('.user-project-list-tasks[data-project="' + backboneViewObject.projectId + '"][data-list="' + list.id + '"]')
						backboneViewObject.taskViews[list.id] = taskViewTemplate
				else
					window.unityApp.showError( window.unityApp.i18n.error.message )

TaskView = Backbone.View.extend
	initialize: ->
		this.taskCollection = new window.unityApp.TaskCollection()
		this.projectId = parseInt( $(this.el).data('project'), 10)
		this.listId = parseInt( $(this.el).data('list'), 10)
		this.render()

	events:
		'click a.complete': 'complete'
		'click a.edit': 'edit'
		'click a.delete': 'delete'

	render: ->
		backboneViewObject = this

		this.taskCollection.fetch
			data:
				list_id: backboneViewObject.listId
				incompleted_only: true
				mine_only: true
			dataType: 'json'
			type: 'GET'
			success: (collection, response) ->
				if response
					$(backboneViewObject.el).empty()

					taskViewTemplate = _.template $('#templates-backbone-tasks').html(), tasks: response

					$(backboneViewObject.el).append taskViewTemplate

					$('.task .actions a').tooltip()

					$('.task').each () ->
						parsedHTML = $(this).find('p:first').html().autoLink({ target: "_blank" })
						$(this).find('p:first').html parsedHTML
						true
				else
					window.unityApp.showError( window.unityApp.i18n.error.message )

	complete: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		bootbox.confirm 'Are you sure you want to mark this task as complete?', (answer) ->
			if answer
				taskId = parseInt( $(infoElement).data('id'), 10)
				task = backboneViewObject.taskCollection.get taskId
				
				taskAttributes = {
					completed: true
				}

				task.save(
					taskAttributes
					success: (model, response) ->
						backboneViewObject.render()

						true
				)
			false

		false

	edit: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		taskId = parseInt( $(infoElement).data('id'), 10)

		dialogData = {
			modal:
				header: 'Edit Task'
				identifier: 'tasks-edit'
			info:
				model: 'Task'
				crud: 'update'
				url: backboneViewObject.taskCollection.url
				project: backboneViewObject.projectId
				list: backboneViewObject.listId
			users: window.unityApp.projectView.userViews[backboneViewObject.projectId].userCollection.toJSON()
			task: backboneViewObject.taskCollection.get taskId
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Update Task'
		}

		window.unityApp.showDialog 'tasks-edit', dialogData, buttonData
		
		$('input[name="due_date"]').datepicker()

	delete: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		bootbox.confirm 'Are you sure you want to remove this task? This action is irreversible!', (answer) ->
			if answer
				taskId = parseInt( $(infoElement).data('id'), 10)
				task = backboneViewObject.taskCollection.get taskId
				
				task.destroy
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
				project_id: parseInt( $(this.el).data('project'), 10)
			dataType: 'json'
			type: 'GET'