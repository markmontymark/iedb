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
        command: 'rm -f *.queries *.results'
      spawn_query_logs:
        command: './spawn-query-logs.coffee -f logs/log1.txt -f logs/log2.txt -o spawn-res',
    docco:
      debug:
        src: ['*.coffee']
        options:
          output: './docs'
  # Load the plugin that provides the "uglify" task.
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-exec'
  grunt.loadNpmTasks 'grunt-docco'

  # Default task(s).
  #grunt.registerTask 'default', ['exec:clean','coffee','exec:query_logs']
  grunt.registerTask 'default', ['exec:clean','exec:spawn_query_logs']
  grunt.registerTask 'docco', ['docco']
