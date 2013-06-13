from projects.models import *
from django.contrib import admin

class ProjectAdmin(admin.ModelAdmin):
	prepopulated_fields = {"slug": ("name",)}
	search_fields = ['name']
	date_hierarchy = 'date'
	list_filter = ['date']
	list_display = ('name', 'slug', 'company', 'date', 'archived')

class MilestoneAdmin(admin.ModelAdmin):
	prepopulated_fields = {"slug": ("name",)}
	search_fields = ['name']
	list_display = ('name', 'slug' )

class DiscussionAdmin(admin.ModelAdmin):
	prepopulated_fields = {"slug": ("title",)}
	search_fields = ['title']
	list_display = ('title', 'slug', 'date' )

class ListAdmin(admin.ModelAdmin):
	prepopulated_fields = {"slug": ("name",)}
	search_fields = ['name']
	list_display = ('name', 'slug' )

class TaskAdmin(admin.ModelAdmin):
	prepopulated_fields = {"slug": ("title",)}
	search_fields = ['title']
	list_display = ('title', 'slug' )

class FileAdmin(admin.ModelAdmin):
	prepopulated_fields = {"slug": ("name",)}
	search_fields = ['name']
	list_display = ('name', 'slug', 'date' )

class CompanyAdmin(admin.ModelAdmin):
	prepopulated_fields = {"slug": ("name",)}
	search_fields = ['name']
	list_display = ('name', 'slug' )

admin.site.register(Project, ProjectAdmin)
admin.site.register(Milestone, MilestoneAdmin)
admin.site.register(Discussion, DiscussionAdmin)
admin.site.register(DiscussionComment)
admin.site.register(List, ListAdmin)
admin.site.register(Task, TaskAdmin)
admin.site.register(File, FileAdmin)
admin.site.register(FileComment)
admin.site.register(Company, CompanyAdmin)

# TODO Chatrooms 