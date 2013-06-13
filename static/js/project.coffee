$(document).ready ->
	window.unityApp.listView = new ListView el: $('#project-lists')
	window.unityApp.milestoneView = new MilestoneView el: $('#project-milestones')
	window.unityApp.discussionView = new DiscussionView el: $('#project-discussions')
	window.unityApp.fileView = new FileView el: $('#project-files')

	# Add List
	$(document).on 'click.unity', 'a.lists-new', (event) -> 
		event.preventDefault()

		anchorElement = event.target

		dialogData = {
			modal:
				header: 'Create a New List'
				identifier: 'lists-new'
			info:
				model: 'List'
				crud: 'create'
				url: window.unityApp.listView.listCollection.url
			milestones: window.unityApp.milestoneView.milestoneCollection.toJSON()
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Create List'
		}

		window.unityApp.showDialog $(anchorElement).data('dialog'), dialogData, buttonData

		false

	# Save List button
	$(document).on 'click.unity', '.modal[data-identifier=' + Sha1.hash('lists-new') + '] .modal-footer .btn-primary', (event) ->
		event.preventDefault();
		$('div.dialog-form.lists-new form').trigger 'submit' 

		true

	# Save List
	$(document).on 'submit.unity', 'div.dialog-form.lists-new form', (event) ->
		event.preventDefault()
		window.unityApp.startLoading()

		formElement = event.target

		list = new window.unityApp.List()

		listAttributes = {
			project: 
				id: $('#main').data 'project'
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
				window.unityApp.listView.render()
				window.unityApp.stopLoading()
				window.unityApp.closeAllDialogs()

				true
		)

		false

	# Add Milestone
	$(document).on 'click.unity', 'a.milestones-new', (event) -> 
		event.preventDefault()

		anchorElement = event.target

		dialogData = {
			modal:
				header: 'Create a New Milestone'
				identifier: 'milestones-new'
			info:
				model: 'Milestone'
				crud: 'create'
				url: window.unityApp.milestoneView.milestoneCollection.url
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Create Milestone'
		}

		window.unityApp.showDialog $(anchorElement).data('dialog'), dialogData, buttonData

		$('input[name="due_date"]').datepicker()

		false

	# Save Milestone button
	$(document).on 'click.unity', '.modal[data-identifier=' + Sha1.hash('milestones-new') + '] .modal-footer .btn-primary', (event) ->
		event.preventDefault();
		$('div.dialog-form.milestones-new form').trigger 'submit' 

		true

	# Save Milestone
	$(document).on 'submit.unity', 'div.dialog-form.milestones-new form', (event) ->
		event.preventDefault()
		window.unityApp.startLoading()

		formElement = event.target

		milestone = new window.unityApp.Milestone()

		milestoneAttributes = {
			project: 
				id: $('#main').data 'project'
			name: $(formElement).find('input[name="name"]').val()
			due_date: $(formElement).find('input[name="due_date"]').val()
			description: $(formElement).find('textarea[name="description"]').val()
		}

		milestone.save(
			milestoneAttributes
			success: (model, response) ->
				window.unityApp.milestoneView.render()
				window.unityApp.stopLoading()
				window.unityApp.closeAllDialogs()

				true
		)

		false

	# Add Discussion
	$(document).on 'click.unity', 'a.discussions-new', (event) -> 
		event.preventDefault()

		anchorElement = event.target

		dialogData = {
			modal:
				header: 'Create a New Discussion'
				identifier: 'discussions-new'
			info:
				model: 'Discussion'
				crud: 'create'
				url: window.unityApp.discussionView.discussionCollection.url
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Create Discussion'
		}

		window.unityApp.showDialog $(anchorElement).data('dialog'), dialogData, buttonData

		false

	# Save Discussion button
	$(document).on 'click.unity', '.modal[data-identifier=' + Sha1.hash('discussions-new') + '] .modal-footer .btn-primary', (event) ->
		event.preventDefault();
		$('div.dialog-form.discussions-new form').trigger 'submit' 

		true

	# Save Discussion
	$(document).on 'submit.unity', 'div.dialog-form.discussions-new form', (event) ->
		event.preventDefault()
		window.unityApp.startLoading()

		formElement = event.target

		discussion = new window.unityApp.Discussion()

		discussionAttributes = {
			project: 
				id: $('#main').data 'project'
			title: $(formElement).find('input[name="title"]').val()
			content: $(formElement).find('textarea[name="content"]').val()
		}

		if $(formElement).find('input[name="private"]').length
			discussionAttributes.private = $(formElement).find('input[name="private"]').prop('checked')

		discussion.save(
			discussionAttributes
			success: (model, response) ->
				window.unityApp.discussionView.render()

				if $(formElement).find('input[name="files"]').val()
					# Do file upload now that we have the discussion

					$.ajax '/ajax/files',
						data:
							project: $('#main').data 'project'
							id: discussion.id
							object: 'd'
						files: $(formElement).find('input[name="files"]')
						iframe: true
						dataType: 'json'

						success: (response) ->
							window.unityApp.stopLoading()

							if !response || response.error
								window.unityApp.showError( response.msg )
							else
								window.unityApp.fileView.render()
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

	true

# Views
ListView = Backbone.View.extend
	initialize: ->
		this.listCollection = new window.unityApp.ListCollection()
		this.render()

	events:
		'click a.delete': 'delete'

	render: ->
		backboneViewObject = this

		this.listCollection.fetch
			data:
				project_id: $('#main').data 'project'
				incompleted_only: true
			dataType: 'json'
			type: 'GET'
			success: (collection, response) ->
				if response
					$(backboneViewObject.el).empty()

					listViewTemplate = _.template $('#templates-backbone-list').html(), lists: response

					$(backboneViewObject.el).append listViewTemplate

					$('.list .actions a').tooltip()

					$('.list').each () ->
						parsedHTML = $(this).find('p:first').html().autoLink({ target: "_blank" })
						$(this).find('p:first').html parsedHTML
						true
				else
					window.unityApp.showError( window.unityApp.i18n.error.message )

	delete: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		bootbox.confirm 'Are you sure you want to remove this list? This action is irreversible!', (answer) ->
			if answer
				listId = parseInt( $(infoElement).data('id'), 10)
				list = backboneViewObject.listCollection.get listId
				list.destroy
					success: ->
						backboneViewObject.render()
			false

		false

MilestoneView = Backbone.View.extend
	initialize: ->
		this.milestoneCollection = new window.unityApp.MilestoneCollection()
		this.render()

	events:
		'click a.delete': 'delete'

	render: ->
		backboneViewObject = this

		this.milestoneCollection.fetch
			data:
				project_id: $('#main').data 'project'
				incompleted_only: true
			dataType: 'json'
			type: 'GET'
			success: (collection, response) ->
				if response
					$(backboneViewObject.el).empty()

					milestoneViewTemplate = _.template $('#templates-backbone-milestone').html(), milestones: response

					$(backboneViewObject.el).append milestoneViewTemplate

					$('.milestone .actions a').tooltip()

					$('.list').each () ->
						parsedHTML = $(this).find('p:first').html().autoLink({ target: "_blank" })
						$(this).find('p:first').html parsedHTML
						true
				else
					window.unityApp.showError( window.unityApp.i18n.error.message )

	delete: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		bootbox.confirm 'Are you sure you want to remove this milestone? This action is irreversible!', (answer) ->
			if answer
				milestoneId = parseInt( $(infoElement).data('id'), 10)
				milestone = backboneViewObject.milestoneCollection.get milestoneId
				milestone.destroy
					success: ->
						backboneViewObject.render()
			false

		false

DiscussionView = Backbone.View.extend
	initialize: ->
		this.discussionCollection = new window.unityApp.DiscussionCollection()
		this.render()

	events:
		'click a.delete': 'delete'

	render: ->
		backboneViewObject = this

		this.discussionCollection.fetch
			data:
				project_id: $('#main').data 'project'
				incompleted_only: true
			dataType: 'json'
			type: 'GET'
			success: (collection, response) ->
				if response
					$(backboneViewObject.el).empty()

					discussionViewTemplate = _.template $('#templates-backbone-discussion').html(), discussions: response

					$(backboneViewObject.el).append discussionViewTemplate

					$('.discussion .actions a').tooltip()

					$('.discussion').each () ->
						parsedHTML = $(this).find('p:last').html().autoLink({ target: "_blank" })
						$(this).find('p:last').html parsedHTML
						true
				else
					window.unityApp.showError( window.unityApp.i18n.error.message )

	delete: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		bootbox.confirm 'Are you sure you want to remove this discussion? This action is irreversible!', (answer) ->
			if answer
				discussionId = parseInt( $(infoElement).data('id'), 10)
				discussion = backboneViewObject.discussionCollection.get discussionId
				discussion.destroy
					success: ->
						backboneViewObject.render()
			false

		false

FileView = Backbone.View.extend
	initialize: ->
		this.fileCollection = new window.unityApp.FileCollection()
		this.render()

	events:
		'click a.delete': 'delete'

	render: ->
		backboneViewObject = this

		this.fileCollection.fetch
			data:
				project_id: $('#main').data 'project'
			dataType: 'json'
			type: 'GET'
			success: (collection, response) ->
				if response
					$(backboneViewObject.el).empty()

					fileViewTemplate = _.template $('#templates-backbone-file').html(), files: response

					$(backboneViewObject.el).append fileViewTemplate

					$('.file .actions a').tooltip()
				else
					window.unityApp.showError( window.unityApp.i18n.error.message )

	delete: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		bootbox.confirm 'Are you sure you want to remove this file? This action is irreversible!', (answer) ->
			if answer
				fileId = parseInt( $(infoElement).data('id'), 10)
				file = backboneViewObject.fileCollection.get fileId
				file.destroy
					success: ->
						backboneViewObject.render()
			false

		false