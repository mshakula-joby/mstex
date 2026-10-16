#!/bin/sh

# 1. Update index so Git instantly recognizes VS Code saves
git update-index -q --refresh > /dev/null 2>&1

FIRSTTAG=$(git describe --tags --always --dirty='-*' 2>/dev/null)
RELTAG=$(git describe --tags --long --always --dirty='-*' --match 'v[0-9]*' 2>/dev/null)

# 2. Output the standard gitinfo2 metadata payload FIRST
git --no-pager log -1 --date=short --decorate=short \
    --pretty=format:"\usepackage[%
        shash={%h},
        lhash={%H},
        authname={%an},
        authemail={%ae},
        authsdate={%ad},
        authidate={%ai},
        authudate={%at},
        commname={%cn},
        commemail={%ce},
        commsdate={%cd},
        commidate={%ci},
        commudate={%ct},
        refnames={%d},
        firsttagdescribe={$FIRSTTAG},
        reltag={$RELTAG}
    ]{gitexinfo}" HEAD > .git/gitHeadInfo.gin

# 3. Check ONLY tracked files for modifications (Ignores .aux, .log, .pdf, etc.)
if ! git diff-index --quiet HEAD --; then
    # Use printf to safely append the macro.
    printf "\n\\def\\gitDirty{1}\n" >> .git/gitHeadInfo.gin
fi

exit 0