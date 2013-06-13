$(document).ready ->
	window.unityApp.milestoneView = new MilestoneView el: $('#project-milestones')
	window.unityApp.completedMilestoneView = new CompleteMilestoneView el: $('#project-complete-milestones')

	# View Completed Milestones
	$(document).on 'click.unity', 'a.milestones-view-complete', (event) -> 
		event.preventDefault()

		$('#project-complete-milestones').closest('section').removeClass('hidden').hide().slideDown 'fast'
		$('a.milestones-hide-complete').removeClass('hidden').show();
		$('a.milestones-view-complete').hide();

		false

	# Hide Completed Milestones
	$(document).on 'click.unity', 'a.milestones-hide-complete', (event) -> 
		event.preventDefault()

		$('#project-complete-milestones').closest('section').slideUp 'fast'
		$('a.milestones-hide-complete').hide();
		$('a.milestones-view-complete').show();

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
			description: $(formElement).find('textarea[name="description"]').val()
			due_date: $(formElement).find('input[name="due_date"]').val()
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

	# Update Milestone button
	$(document).on 'click.unity', '.modal[data-identifier=' + Sha1.hash('milestones-edit') + '] .modal-footer .btn-primary', (event) ->
		event.preventDefault();
		$('div.dialog-form.milestones-edit form').trigger 'submit' 

		true

	# Update Milestone
	$(document).on 'submit.unity', 'div.dialog-form.milestones-edit form', (event) ->
		event.preventDefault()
		window.unityApp.startLoading()

		formElement = event.target

		milestone = window.unityApp.milestoneView.milestoneCollection.get $(formElement).data('id')

		if ! milestone
			milestone = window.unityApp.completedMilestoneView.milestoneCollection.get $(formElement).data('id')

		milestoneAttributes = {
			name: $(formElement).find('input[name="name"]').val()
			description: $(formElement).find('textarea[name="description"]').val()
			due_date: $(formElement).find('input[name="due_date"]').val()
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

	true

# Views
MilestoneView = Backbone.View.extend
	initialize: ->
		this.milestoneCollection = new window.unityApp.MilestoneCollection()
		this.render()

	events:
		'click a.complete': 'complete'
		'click a.edit': 'edit'
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

					$('.milestone').each () ->
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

		bootbox.confirm 'Are you sure you want to mark this milestone as complete? All lists and tasks associated to it will be marked as complete also!', (answer) ->
			if answer
				milestoneId = parseInt( $(infoElement).data('id'), 10)
				milestone = backboneViewObject.milestoneCollection.get milestoneId

				milestoneAttributes = {
					completed: true
				}

				milestone.save(
					milestoneAttributes
					success: (model, response) ->
						backboneViewObject.render()
						window.unityApp.completedMilestoneView.render()

						true
				)
			false

		false

	edit: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		milestoneId = parseInt( $(infoElement).data('id'), 10)

		dialogData = {
			modal:
				header: 'Edit Milestone'
				identifier: 'milestones-edit'
			info:
				model: 'Milestone'
				crud: 'update'
				url: window.unityApp.milestoneView.milestoneCollection.url
			milestone: backboneViewObject.milestoneCollection.get milestoneId
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Update Milestone'
		}

		window.unityApp.showDialog 'milestones-edit', dialogData, buttonData
		
		$('input[name="due_date"]').datepicker()

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
						window.unityApp.completedMilestoneView.render()

						true
			false

		false


CompleteMilestoneView = Backbone.View.extend
	initialize: ->
		this.milestoneCollection = new window.unityApp.MilestoneCollection()
		this.render()

	events:
		'click a.incomplete': 'incomplete'
		'click a.edit': 'edit'
		'click a.delete': 'delete'

	render: ->
		backboneViewObject = this

		this.milestoneCollection.fetch
			data:
				project_id: $('#main').data 'project'
				completed_only: true
			dataType: 'json'
			type: 'GET'
			success: (collection, response) ->
				if response
					$(backboneViewObject.el).empty()

					milestoneViewTemplate = _.template $('#templates-backbone-complete-milestone').html(), milestones: response

					$(backboneViewObject.el).append milestoneViewTemplate

					$('.milestone .actions a').tooltip()

					$('.milestone').each () ->
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

		bootbox.confirm 'Are you sure you want to mark this milestone as incomplete?', (answer) ->
			if answer
				milestoneId = parseInt( $(infoElement).data('id'), 10)
				milestone = backboneViewObject.milestoneCollection.get milestoneId

				milestoneAttributes = {
					completed: false
				}

				milestone.save(
					milestoneAttributes
					success: (model, response) ->
						backboneViewObject.render()
						window.unityApp.milestoneView.render()

						true
				)
			false

		false

	edit: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		milestoneId = parseInt( $(infoElement).data('id'), 10)

		dialogData = {
			modal:
				header: 'Edit Milestone'
				identifier: 'milestones-edit'
			info:
				model: 'Milestone'
				crud: 'update'
				url: window.unityApp.milestoneView.milestoneCollection.url
			milestone: backboneViewObject.milestoneCollection.get milestoneId
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Update Milestone'
		}

		window.unityApp.showDialog 'milestones-edit', dialogData, buttonData
		
		$('input[name="due_date"]').datepicker()

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
						window.unityApp.milestoneView.render()

						true
			false

		false