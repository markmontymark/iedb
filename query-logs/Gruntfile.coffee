module.exports = (grunt) ->
  #/ Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    coffee:
      glob_to_multiple:
        expand: true
        cwd: './'
        src: ['*.coffee']
        dest: './'
        ext: '.js'
    exec:
      clean:
        command: 'rm -f queries results'
        stdout: true
        stderr: true
      query_logs:
        command: './query-logs.coffee logs/*.txt',
        stdout: true
        stderr: true
  # Load the plugin that provides the "uglify" task.
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-exec'

  # Default task(s).
  grunt.registerTask 'default', ['exec:clean','coffee','exec:query_logs']
