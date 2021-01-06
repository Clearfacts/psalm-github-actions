#!/bin/sh -l
set -e

TAINT_ANALYSIS=""
if [ "$INPUT_SECURITY_ANALYSIS" = "true" ]; then
    TAINT_ANALYSIS="--taint-analysis"
fi

REPORT=""
if [ ! -z "$INPUT_REPORT_FILE" ]; then
    REPORT="--report=$INPUT_REPORT_FILE"
fi

if test -f "composer.json"; then
    composer global config github-oauth.github.com "$INPUT_COMPOSER_GITHUB_TOKEN"

    IGNORE_PLATFORM_REQS=""
    if [ "$CHECK_PLATFORM_REQUIREMENTS" = "false" ] || [ "$INPUT_COMPOSER_CHECK_PLATFORM_REQUIREMENTS" = "false" ]; then
        IGNORE_PLATFORM_REQS="--ignore-platform-reqs"
    fi

    NO_DEV="--no-dev"
    if [ "$REQUIRE_DEV" = "true" ] || [ "$INPUT_COMPOSER_REQUIRE_DEV" = "true"  ]; then
        NO_DEV=""
    fi

    COMPOSER_COMMAND="composer install --no-scripts --no-progress $NO_DEV $IGNORE_PLATFORM_REQS"
    echo "::group::$COMPOSER_COMMAND"
    $COMPOSER_COMMAND
    echo "::endgroup::"
else 
    echo "composer.json not found in repo, skipping Composer installation"
fi

CONFIG_FILE="--config=$GITHUB_WORKSPACE/psalm.xml"

echo "Test:"
find / -type f -name psalm.xml
ls -al $GITHUB_WORKSPACE
cat "$GITHUB_WORKSPACE/psalm.xml"

/composer/vendor/bin/psalm --version
/composer/vendor/bin/psalm --output-format=github $CONFIG_FILE $TAINT_ANALYSIS $REPORT
