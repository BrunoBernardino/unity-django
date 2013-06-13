$(document).ready ->
	window.unityApp.listView = new ListView el: $('#project-lists')
	window.unityApp.completedListView = new CompletedListView el: $('#project-complete-lists')
	window.unityApp.milestoneView = new MilestoneView

	# View Completed Lists
	$(document).on 'click.unity', 'a.lists-view-complete', (event) -> 
		event.preventDefault()

		$('#project-complete-lists').closest('section').removeClass('hidden').hide().slideDown 'fast'
		$('a.lists-hide-complete').removeClass('hidden').show();
		$('a.lists-view-complete').hide();

		false

	# Hide Completed Lists
	$(document).on 'click.unity', 'a.lists-hide-complete', (event) -> 
		event.preventDefault()

		$('#project-complete-lists').closest('section').slideUp 'fast'
		$('a.lists-hide-complete').hide();
		$('a.lists-view-complete').show();

		false

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

		list = window.unityApp.listView.listCollection.get $(formElement).data('id')

		if ! list
			list = window.unityApp.completedListView.listCollection.get $(formElement).data('id')

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
				window.unityApp.listView.render()
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
		'click a.complete': 'complete'
		'click a.edit': 'edit'
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

	complete: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		bootbox.confirm 'Are you sure you want to mark this list as complete? This will complete all the tasks related to it!', (answer) ->
			if answer
				listId = parseInt( $(infoElement).data('id'), 10)
				list = backboneViewObject.listCollection.get listId
				
				listAttributes = {
					completed: true
				}

				list.save(
					listAttributes
					success: (model, response) ->
						backboneViewObject.render()
						window.unityApp.completedListView.render()

						true
				)
			false

		false

	edit: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		listId = parseInt( $(infoElement).data('id'), 10)

		dialogData = {
			modal:
				header: 'Edit List'
				identifier: 'lists-edit'
			info:
				model: 'List'
				crud: 'update'
				url: window.unityApp.listView.listCollection.url
			milestones: window.unityApp.milestoneView.milestoneCollection.toJSON()
			list: backboneViewObject.listCollection.get listId
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Update List'
		}

		window.unityApp.showDialog 'lists-edit', dialogData, buttonData

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
						window.unityApp.completedListView.render()

						true
			false

		false

CompletedListView = Backbone.View.extend
	initialize: ->
		this.listCollection = new window.unityApp.ListCollection()
		this.render()

	events:
		'click a.incomplete': 'incomplete'
		'click a.edit': 'edit'
		'click a.delete': 'delete'

	render: ->
		backboneViewObject = this

		this.listCollection.fetch
			data:
				project_id: $('#main').data 'project'
				completed_only: true
			dataType: 'json'
			type: 'GET'
			success: (collection, response) ->
				if response
					$(backboneViewObject.el).empty()

					listViewTemplate = _.template $('#templates-backbone-complete-list').html(), lists: response

					$(backboneViewObject.el).append listViewTemplate

					$('.list .actions a').tooltip()

					$('.list').each () ->
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

		bootbox.confirm 'Are you sure you want to mark this list as incomplete?', (answer) ->

			if answer
				listId = parseInt( $(infoElement).data('id'), 10)
				list = backboneViewObject.listCollection.get listId
				
				listAttributes = {
					completed: false
				}

				list.save(
					listAttributes
					success: (model, response) ->
						backboneViewObject.render()
						window.unityApp.listView.render()

						true
				)
			false

		false

	edit: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		listId = parseInt( $(infoElement).data('id'), 10)

		dialogData = {
			modal:
				header: 'Edit List'
				identifier: 'lists-edit'
			info:
				model: 'List'
				crud: 'update'
				url: window.unityApp.listView.listCollection.url
			milestones: window.unityApp.milestoneView.milestoneCollection.toJSON()
			list: backboneViewObject.listCollection.get listId
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Update List'
		}

		window.unityApp.showDialog 'lists-edit', dialogData

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
						window.unityApp.listView.render()

						true
			false
		
		false

MilestoneView = Backbone.View.extend
	initialize: ->
		this.milestoneCollection = new window.unityApp.MilestoneCollection()

		this.milestoneCollection.fetch
			data:
				project_id: $('#main').data 'project'
			dataType: 'json'
			type: 'GET'