require! {
  gulp
  \gulp-livescript : livescript
  \gulp-jasmine : jasmine
  \jasmine-spec-reporter : SpecReporter
}

test-files = <[ ./test/**/*.js ]>
src-test-ls-files = <[ ./src/test/**/*.ls ]>
src-lib-ls-files = <[ ./src/lib/**/*.ls ]>


gulp.task \src-lib ->
  gulp.src src-lib-ls-files
    .pipe livescript!
    .pipe gulp.dest './lib'

gulp.task \src-test ->
  gulp.src src-test-ls-files
    .pipe livescript!
    .pipe gulp.dest './test'

gulp.task \jasmine <[ build ]> ->
  gulp.src test-files
    .pipe jasmine do
      reporter: new Spec-reporter

gulp.task \karma (done) ->
  karma.start do
    config-file: "#__dirname/karma.conf.js"
    single-run: true
    done

gulp.task \watch ->
  gulp.watch src-lib-ls-files, <[ src-lib ]>
  gulp.watch src-test-ls-files, <[ src-test ]>

gulp.task \build <[ src-lib src-test ]>

gulp.task \default <[ build watch ]>
