#!/bin/sh
# Gate the staged Webi installer review and print the next allowed action.

set -eu

usage() {
    printf '%s\n' \
        "usage: $0 start PR_URL PART1_REPORT" \
        "       $0 show PART REPORT --confirm" \
        "       $0 beta REPORT_DIR PACKAGE --authorize" \
        "       $0 beta REPORT_DIR REPORT_PREFIX PACKAGE --authorize" >&2
}

fail() {
    printf 'error: %s\n' "$1" >&2
    exit 1
}

show_report() {
    part=$1
    report=$2
    test -f "$report" || fail "missing report: $report"
    printf '%s\n' "Report ready: $report"
    printf '%s\n' "REQUIRED TOOL CALL: use the read tool on $report so the reviewer harness displays the full Markdown report."
    printf '%s\n' "REQUIRED RESPONSE: include the complete report from read plus the stage summary; do not reconstruct it from memory or give only a recommendation."
}

find_previous() {
    report=$1
    previous=$2
    report_dir=$(dirname "$report")
    report_name=$(basename "$report")
    prefix=${report_name%-part-*.md}
    find "$report_dir" -type f -maxdepth 1 -name "${prefix}-part-${previous}.md" -print
}

find_previous_for_package() {
    report_dir=$1
    package=$2
    previous=$3
    find "$report_dir" -type f -maxdepth 1 -name "*-$package-part-$previous.md" -print
}

next_for_part() {
    part=$1
    report=$2
    case "$part" in
        1)
            printf '%s\n' \
                'STOP: wait for human confirmation before Part 2.' \
                "NEXT: write Part 2 using references/part-2.md, then run:" \
                "  sh skills/review-webi-installer/scripts/review.sh show 2 <part-2-report> --confirm"
            ;;
        2)
            printf '%s\n' \
                'STOP: wait for human confirmation before Part 3.' \
                "NEXT: write Part 3 using references/part-3.md, then run:" \
                "  sh skills/review-webi-installer/scripts/review.sh show 3 <part-3-report> --confirm"
            ;;
        3)
            printf '%s\n' \
                'STOP: wait for human confirmation before Part 4.' \
                "NEXT: write Part 4 using references/part-4.md and the asset script, then run:" \
                "  sh skills/review-webi-installer/scripts/review.sh show 4 <part-4-report> --confirm"
            ;;
        4)
            printf '%s\n' \
                'STOP: wait for the human operator go-ahead.' \
                "NEXT: after authorization, run:" \
                "  sh skills/review-webi-installer/scripts/review.sh beta <report-dir> <pkg> --authorize" \
                "  # add <report-prefix> before <pkg> when reports are mixed"
            ;;
        *)
            fail "unknown part: $part"
            ;;
    esac
}

if test "$#" -lt 1; then
    usage
    exit 2
fi

command=$1
shift
case "$command" in
    start)
        test "$#" -eq 2 || {
            usage
            exit 2
        }
        pr_url=$1
        report=$2
        sh "$(dirname "$0")/part1-report.sh" "$pr_url" "$report"
        show_report 1 "$report"
        next_for_part 1 "$report"
        ;;
    show)
        test "$#" -eq 3 || {
            usage
            exit 2
        }
        part=$1
        report=$2
        confirmation=$3
        test "$confirmation" = '--confirm' || fail 'human confirmation is required: use --confirm'
        case "$part" in
            1 | 2 | 3 | 4) ;;
            *) fail "part must be 1, 2, 3, or 4" ;;
        esac
        if test "$part" -gt 1; then
            previous=$((part - 1))
            previous_count=$(find_previous "$report" "$previous" | wc -l | tr -d ' ')
            test "$previous_count" -eq 1 || fail "need exactly one Part $previous report matching $report"
        fi
        show_report "$part" "$report"
        next_for_part "$part" "$report"
        ;;
    beta)
        test "$#" -eq 3 || test "$#" -eq 4 || {
            usage
            exit 2
        }
        report_dir=$1
        if test "$#" -eq 3; then
            report_prefix=''
            package=$2
            authorization=$3
        else
            report_prefix=$2
            package=$3
            authorization=$4
        fi
        test "$authorization" = '--authorize' || fail 'human operator go-ahead is required: use --authorize'
        for part in 1 2 3 4; do
            if test -n "$report_prefix"; then
                candidate="$report_dir/$report_prefix-part-$part.md"
                count=$(test -f "$candidate" && printf '1' || printf '0')
            else
                count=$(find_previous_for_package "$report_dir" "$package" "$part" | wc -l | tr -d ' ')
            fi
            test "$count" -eq 1 || fail "need exactly one Part $part report in $report_dir"
        done
        printf '%s\n' \
            'All four reports are present.' \
            'Human approval was supplied.' \
            'The harness does not deploy. The AI may now run the approved command:' \
            "  ./scripts/deploy-installers.sh beta.webi.sh $package"
        ;;
    *)
        usage
        exit 2
        ;;
esac
