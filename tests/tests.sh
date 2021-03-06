#!/bin/bash
set -e

current_directory=$(pwd)
test_framework_directory="$current_directory/.."
working_directory="$current_directory/.testing"
sh_unit_directory="$working_directory/shunit2"

version="256.0-test"
jenkinsfile_runner_tag="jenkins-experimental/jenkinsfile-runner-test-image"

downloaded_cwp_jar="to_update"

. $test_framework_directory/init-jfr-test-framework.inc

oneTimeSetUp() {
  downloaded_cwp_jar=$(download_cwp "$test_framework_directory")
}

test_with_tag() {
  jfr_tag=$(execute_cwp_jar_and_generate_docker_image "$test_framework_directory" "$downloaded_cwp_jar" "$version" "$current_directory/test_resources/test_with_tag/packager-config.yml" "$jenkinsfile_runner_tag" | grep 'Successfully tagged')
  execution_should_success "$?" "$jfr_tag" "$jenkinsfile_runner_tag"
  
  result=$(run_jfr_docker_image "$jenkinsfile_runner_tag" "$current_directory/test_resources/test_with_tag/Jenkinsfile")
  jenkinsfile_execution_should_succed "$?" "$result"
}

test_java_opts() {
  jfr_tag=$(execute_cwp_jar_and_generate_docker_image "$test_framework_directory" "$downloaded_cwp_jar" "$version" "$current_directory/test_resources/test_with_tag/packager-config.yml" "$jenkinsfile_runner_tag" | grep 'Successfully tagged')
  execution_should_success "$?" "$jfr_tag" "$jenkinsfile_runner_tag"

  result=$(run_jfr_docker_image "$jenkinsfile_runner_tag" "$current_directory/test_resources/test_with_tag/Jenkinsfile")
  jenkinsfile_execution_should_succed "$?" "$result"

  export JAVA_OPTS="-Xmx1M -Xms100G"
  result=$(run_jfr_docker_image "$jenkinsfile_runner_tag" "$current_directory/test_resources/test_with_tag/Jenkinsfile")
  assertEquals "Should retrieve exit code 0" "0" "$?"
  message_not_contains "$result" "[Pipeline] End of Pipeline"
  message_not_contains "$result" "Finished: SUCCESS"
  message_contains "$result" "Initial heap size set to a larger value than the maximum heap size"
  unset JAVA_OPTS
}

test_with_default_tag() {
  jfr_tag=$(execute_cwp_jar_and_generate_docker_image "$test_framework_directory" "$downloaded_cwp_jar" "$version" "$current_directory/test_resources/test_with_tag/packager-config.yml" | grep 'Successfully tagged')
  execution_should_success "$?" "$jfr_tag" "test_with_default_tag"
}

test_download_cwp_version() {
  default_cwp_jar=$(download_cwp "$test_framework_directory")
  execution_should_success "$?" "$default_cwp_jar" "cwp-cli-$DEFAULT_CWP_VERSION.jar"

  another_cwp_jar=$(download_cwp "$test_framework_directory" "1.3")
  execution_should_success "$?" "$another_cwp_jar" "cwp-cli-1.3.jar"
}

test_with_tag_using_cwp_docker_image() {
  jfr_tag=$(generate_docker_image_from_cwp_docker_image "$current_directory/test_resources/test_with_tag_using_cwp_docker_image/packager-config.yml" "$jenkinsfile_runner_tag" | grep 'Successfully tagged')
  execution_should_success "$?" "$jfr_tag" "$jenkinsfile_runner_tag"
  
  result=$(run_jfr_docker_image "$jenkinsfile_runner_tag" "$current_directory/test_resources/test_with_tag_using_cwp_docker_image/Jenkinsfile")
  jenkinsfile_execution_should_succed "$?" "$result"
}

test_with_default_tag_using_cwp_docker_image() {
  jfr_tag=$(generate_docker_image_from_cwp_docker_image "$current_directory/test_resources/test_with_default_tag_using_cwp_docker_image/packager-config.yml" | grep 'Successfully tagged')
  execution_should_success "$?" "$jfr_tag" "test_with_default_tag_using_cwp_docker_image"
}

test_failing_docker_image() {
  result=$(execute_cwp_jar_and_generate_docker_image "$test_framework_directory" "$downloaded_cwp_jar" "$version" "$current_directory/test_resources/test_failing_docker_image/packager-config.yml")
  docker_generation_should_fail "$?" "$result"
}

test_jenkinsfile_fail() {
  jfr_tag=$(execute_cwp_jar_and_generate_docker_image "$test_framework_directory" "$downloaded_cwp_jar" "$version" "$current_directory/test_resources/test_with_tag/packager-config.yml" "$jenkinsfile_runner_tag" | grep 'Successfully tagged')
  execution_should_success "$?" "$jfr_tag" "$jenkinsfile_runner_tag"

  result=$(run_jfr_docker_image "$jenkinsfile_runner_tag" "$current_directory/test_resources/test_jenkinsfile_fail/Jenkinsfile")
  jenkinsfile_execution_should_fail "$?" "$result"
}

test_jenkinsfile_unstable() {
  jfr_tag=$(execute_cwp_jar_and_generate_docker_image "$test_framework_directory" "$downloaded_cwp_jar" "$version" "$current_directory/test_resources/test_with_tag/packager-config.yml" "$jenkinsfile_runner_tag" | grep 'Successfully tagged')
  execution_should_success "$?" "$jfr_tag" "$jenkinsfile_runner_tag"

  result=$(run_jfr_docker_image "$jenkinsfile_runner_tag" "$current_directory/test_resources/test_jenkinsfile_unstable/Jenkinsfile")
  jenkinsfile_execution_should_be_unstable "$?" "$result"
}

. $sh_unit_directory/shunit2
