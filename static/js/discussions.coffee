$(document).ready ->
	window.unityApp.discussionView = new DiscussionView el: $('#project-discussions')
	window.unityApp.completedDiscussionView = new CompleteDiscussionView el: $('#project-complete-discussions')

	# View Completed Discussions
	$(document).on 'click.unity', 'a.discussions-view-complete', (event) -> 
		event.preventDefault()

		$('#project-complete-discussions').closest('section').removeClass('hidden').hide().slideDown 'fast'
		$('a.discussions-hide-complete').removeClass('hidden').show();
		$('a.discussions-view-complete').hide();

		false

	# Hide Completed Discussions
	$(document).on 'click.unity', 'a.discussions-hide-complete', (event) -> 
		event.preventDefault()

		$('#project-complete-discussions').closest('section').slideUp 'fast'
		$('a.discussions-hide-complete').hide();
		$('a.discussions-view-complete').show();

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
								window.unityApp.discussionView.render()
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

		discussion = window.unityApp.discussionView.discussionCollection.get $(formElement).data('id')

		if ! discussion
			discussion = window.unityApp.completedDiscussionView.discussionCollection.get $(formElement).data('id')

		discussionAttributes = {
			title: $(formElement).find('input[name="title"]').val()
			content: $(formElement).find('textarea[name="content"]').val()
		}

		if $(formElement).find('input[name="private"]').length
			discussionAttributes.private = $(formElement).find('input[name="private"]').prop('checked')

		discussion.save(
			discussionAttributes
			success: (model, response) ->
				window.unityApp.discussionView.render()
				window.unityApp.stopLoading()
				window.unityApp.closeAllDialogs()

				true
		)

		false

	true

# Views
DiscussionView = Backbone.View.extend
	initialize: ->
		this.discussionCollection = new window.unityApp.DiscussionCollection()
		this.render()

	events:
		'click a.complete': 'complete'
		'click a.edit': 'edit'
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

		bootbox.confirm 'Are you sure you want to mark this discussion as complete?', (answer) ->
			if answer
				discussionId = parseInt( $(infoElement).data('id'), 10)
				discussion = backboneViewObject.discussionCollection.get discussionId
				
				discussionAttributes = {
					completed: true
				}

				discussion.save(
					discussionAttributes
					success: (model, response) ->
						backboneViewObject.render()
						window.unityApp.completedDiscussionView.render()

						true
				)
			false

		false

	edit: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		discussionId = parseInt( $(infoElement).data('id'), 10)

		dialogData = {
			modal:
				header: 'Edit Discussion'
				identifier: 'discussions-edit'
			info:
				model: 'Discussion'
				crud: 'update'
				url: window.unityApp.discussionView.discussionCollection.url
			discussion: backboneViewObject.discussionCollection.get discussionId
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Update Discussion'
		}

		window.unityApp.showDialog 'discussions-edit', dialogData, buttonData

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

CompleteDiscussionView = Backbone.View.extend
	initialize: ->
		this.discussionCollection = new window.unityApp.DiscussionCollection()
		this.render()

	events:
		'click a.incomplete': 'incomplete'
		'click a.edit': 'edit'
		'click a.delete': 'delete'

	render: ->
		backboneViewObject = this

		this.discussionCollection.fetch
			data:
				project_id: $('#main').data 'project'
				completed_only: true
			dataType: 'json'
			type: 'GET'
			success: (collection, response) ->
				if response
					$(backboneViewObject.el).empty()

					discussionViewTemplate = _.template $('#templates-backbone-complete-discussion').html(), discussions: response

					$(backboneViewObject.el).append discussionViewTemplate

					$('.discussion .actions a').tooltip()

					$('.discussion').each () ->
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

		bootbox.confirm 'Are you sure you want to mark this discussion as incomplete?', (answer) ->
			if answer
				discussionId = parseInt( $(infoElement).data('id'), 10)
				discussion = backboneViewObject.discussionCollection.get discussionId
				
				discussionAttributes = {
					completed: false
				}

				discussion.save(
					discussionAttributes
					success: (model, response) ->
						backboneViewObject.render()
						window.unityApp.discussionView.render()

						true
				)
			false

		false

	edit: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		discussionId = parseInt( $(infoElement).data('id'), 10)

		dialogData = {
			modal:
				header: 'Edit Discussion'
				identifier: 'discussions-edit'
			info:
				model: 'Discussion'
				crud: 'update'
				url: window.unityApp.discussionView.discussionCollection.url
			discussion: backboneViewObject.discussionCollection.get discussionId
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Update Discussion'
		}

		window.unityApp.showDialog 'discussions-edit', dialogData, buttonData

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