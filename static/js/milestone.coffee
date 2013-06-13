$(document).ready ->
	window.unityApp.milestoneCollection = new window.unityApp.MilestoneCollection

	window.unityApp.milestoneCollection.fetch
		data:
			project_id: $('#main').data 'project'
		dataType: 'json'
		type: 'GET'

	# Complete Milestone
	$(document).on 'click', 'a.milestone-complete', (event) -> 
		event.preventDefault()

		anchorElement = event.target

		bootbox.confirm 'Are you sure you want to mark this milestone as complete? All lists and tasks associated to it will be marked as complete also!', (answer) ->
			if answer
				window.unityApp.startLoading()
				milestoneId = parseInt( $('#main').data('milestone'), 10)
				milestone = window.unityApp.milestoneCollection.get milestoneId
				
				milestoneAttributes = {
					completed: true
				}

				milestone.save(
					milestoneAttributes
					success: ->
						window.location.reload()

						true
				)
			false

		false

	# Incomplete Milestone
	$(document).on 'click.unity', 'a.milestone-incomplete', (event) -> 
		event.preventDefault()

		anchorElement = event.target

		bootbox.confirm 'Are you sure you want to mark this milestone as incomplete?', (answer) ->
			if answer
				window.unityApp.startLoading()
				milestoneId = parseInt( $('#main').data('milestone'), 10)
				milestone = window.unityApp.milestoneCollection.get milestoneId
				
				milestoneAttributes = {
					completed: false
				}

				milestone.save(
					milestoneAttributes
					success: ->
						window.location.reload()

						true
				)
			false

		false

	# Edit Milestone
	$(document).on 'click.unity', 'a.milestone-edit', (event) ->
		event.preventDefault()

		anchorElement = event.target

		backboneViewObject = this

		milestoneId = parseInt( $('#main').data('milestone'), 10)

		dialogData = {
			modal:
				header: 'Edit Milestone'
				identifier: 'milestones-edit'
			info:
				model: 'Milestone'
				crud: 'update'
				url: window.unityApp.milestoneCollection.url
			milestone: window.unityApp.milestoneCollection.get milestoneId
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Update Milestone'
		}

		window.unityApp.showDialog 'milestones-edit', dialogData, buttonData
		
		$('input[name="due_date"]').datepicker()

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

		milestone = window.unityApp.milestoneCollection.get $(formElement).data('id')

		milestoneAttributes = {
			name: $(formElement).find('input[name="name"]').val()
			description: $(formElement).find('textarea[name="description"]').val()
			due_date: $(formElement).find('input[name="due_date"]').val()
		}

		milestone.save(
			milestoneAttributes
			success: (model, response) ->
				window.location.reload()

				true
		)

		false

	true