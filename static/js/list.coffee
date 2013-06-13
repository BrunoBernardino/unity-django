$(document).ready ->
	window.unityApp.listCollection = new window.unityApp.ListCollection
	window.unityApp.taskView = new TaskView el: $('#project-tasks')
	window.unityApp.completedTaskView = new CompleteTaskView el: $('#project-complete-tasks')
	window.unityApp.userView = new UserView
	window.unityApp.milestoneView = new MilestoneView

	window.unityApp.listCollection.fetch
		data:
			project_id: $('#main').data 'project'
		dataType: 'json'
		type: 'GET'

	# View Completed Tasks
	$(document).on 'click.unity', 'a.list-view-complete', (event) -> 
		event.preventDefault()

		$('#project-complete-tasks').closest('section').removeClass('hidden').hide().slideDown 'fast'
		$('a.list-hide-complete').removeClass('hidden').show();
		$('a.list-view-complete').hide();

		false

	# Hide Completed Tasks
	$(document).on 'click.unity', 'a.list-hide-complete', (event) -> 
		event.preventDefault()

		$('#project-complete-tasks').closest('section').slideUp 'fast'
		$('a.list-hide-complete').hide();
		$('a.list-view-complete').show();

		false

	# Complete List
	$(document).on 'click.unity', 'a.list-complete', (event) -> 
		event.preventDefault()

		anchorElement = event.target

		bootbox.confirm 'Are you sure you want to mark this list as complete? This will complete all the tasks related to it!', (answer) ->
			if answer
				listId = parseInt( $(infoElement).data('id'), 10)
				list = window.unityApp.listCollection.get listId
				
				listAttributes = {
					completed: true
				}

				list.save(
					listAttributes
					success: ->
						window.unityApp.taskView.render()

						true
				)
			false

		false

	# Edit List
	$(document).on 'click.unity', 'a.list-edit', (event) ->
		event.preventDefault()

		anchorElement = event.target

		backboneViewObject = this

		listId = parseInt( $('#main').data('list'), 10)

		dialogData = {
			modal:
				header: 'Edit List'
				identifier: 'lists-edit'
			info:
				model: 'List'
				crud: 'update'
				url: window.unityApp.listCollection.url
			milestones: window.unityApp.milestoneView.milestoneCollection.toJSON()
			list: window.unityApp.listCollection.get listId
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Update List'
		}

		window.unityApp.showDialog $(anchorElement).data('dialog'), dialogData, buttonData

		false

	# Update List button
	$(document).on 'click.unity', '.modal[data-identifier=' + Sha1.hash('lists-edit') + '] .modal-footer .btn-primary', (event) ->
		event.preventDefault();
		$('div.dialog-form.lists-edit form').trigger 'submit' 

		true

	# Update List
	$(document).on 'submit.unity', 'div.dialog-form.lists-edit form', (event) ->
		event.preventDefault()
		window.unityApp.startLoading()

		formElement = event.target

		list = window.unityApp.listCollection.get $(formElement).data('id')

		listAttributes = {
			name: $(formElement).find('input[name="name"]').val()
			milestone: 
				id: $(formElement).find('select[name="milestone"]').val()
			description: $(formElement).find('textarea[name="description"]').val()
		}

		if $(formElement).find('input[name="private"]').length
			listAttributes.private = $(formElement).find('input[name="private"]').prop('checked')

		list.save(
			listAttributes
			success: (model, response) ->
				window.location.reload()

				true
		)

		false

	# Add Task
	$(document).on 'click.unity', 'a.tasks-new', (event) -> 
		event.preventDefault()

		anchorElement = event.target

		dialogData = {
			modal:
				header: 'Create a New Task'
				identifier: 'tasks-new'
			info:
				model: 'Task'
				crud: 'create'
				url: window.unityApp.taskView.taskCollection.url
			users: window.unityApp.userView.userCollection.toJSON()
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

		task = new window.unityApp.Task()

		taskAttributes = {
			list: 
				id: $('#main').data 'list'
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
				window.unityApp.taskView.render()

				if $(formElement).find('input[name="files"]').val()
					# Do file upload now that we have the task

					$.ajax '/ajax/files',
						data:
							project: $('#main').data 'project'
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
								window.unityApp.taskView.render()
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

		task = window.unityApp.taskView.taskCollection.get $(formElement).data('id')

		if ! task
			task = window.unityApp.completedTaskView.taskCollection.get $(formElement).data('id')

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
				window.unityApp.taskView.render()
				window.unityApp.completedTaskView.render()
				window.unityApp.stopLoading()
				window.unityApp.closeAllDialogs()

				true
		)

		false

	true

# Views
TaskView = Backbone.View.extend
	initialize: ->
		this.taskCollection = new window.unityApp.TaskCollection()
		this.render()

	events:
		'click a.complete': 'complete'
		'click a.edit': 'edit'
		'click a.delete': 'delete'

	render: ->
		backboneViewObject = this

		this.taskCollection.fetch
			data:
				list_id: $('#main').data 'list'
				incompleted_only: true
			dataType: 'json'
			type: 'GET'
			success: (collection, response) ->
				if response
					$(backboneViewObject.el).empty()

					taskViewTemplate = _.template $('#templates-backbone-task').html(), tasks: response

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
						window.unityApp.completedTaskView.render()

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
				url: window.unityApp.taskView.taskCollection.url
			users: window.unityApp.userView.userCollection.toJSON()
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
						window.unityApp.completedTaskView.render()

						true
			false

		false


CompleteTaskView = Backbone.View.extend
	initialize: ->
		this.taskCollection = new window.unityApp.TaskCollection()
		this.render()

	events:
		'click a.incomplete': 'incomplete'
		'click a.edit': 'edit'
		'click a.delete': 'delete'

	render: ->
		backboneViewObject = this

		this.taskCollection.fetch
			data:
				list_id: $('#main').data 'list'
				completed_only: true
			dataType: 'json'
			type: 'GET'
			success: (collection, response) ->
				if response
					$(backboneViewObject.el).empty()

					taskViewTemplate = _.template $('#templates-backbone-complete-task').html(), tasks: response

					$(backboneViewObject.el).append taskViewTemplate

					$('.task .actions a').tooltip()

					$('.task').each () ->
						parsedHTML = $(this).find('p:first').html().autoLink({ target: "_blank" })
						$(this).find('p:first').html parsedHTML
						true
				else
					window.unityApp.showError( window.unityApp.i18n.error.message )

	incomplete: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		bootbox.confirm 'Are you sure you want to mark this task as incomplete?', (answer) ->
			if answer
				taskId = parseInt( $(infoElement).data('id'), 10)
				task = backboneViewObject.taskCollection.get taskId
				
				taskAttributes = {
					completed: false
				}

				task.save(
					taskAttributes
					success: (model, response) ->
						backboneViewObject.render()
						window.unityApp.taskView.render()

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
				url: window.unityApp.taskView.taskCollection.url
			users: window.unityApp.userView.userCollection.toJSON()
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
						window.unityApp.taskView.render()

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

MilestoneView = Backbone.View.extend
	initialize: ->
		this.milestoneCollection = new window.unityApp.MilestoneCollection()

		this.milestoneCollection.fetch
			data:
				project_id: $('#main').data 'project'
			dataType: 'json'
			type: 'GET'