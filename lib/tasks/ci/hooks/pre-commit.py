#!/usr/bin/env python

import github3

import fnmatch
import os
import sys

OK = 0
ERR = 1

EXTRAS = ['DataDog/integrations-extras']


# TODO: change this to tokens...
def two_fa():
    code = ''
    while not code:
        code = raw_input('Enter Github 2FA Code: ')

    return code


def get_extras_requirements():
    reqs = {}
    api = github3.login(
        os.environ.get('GHUSER'),
        os.environ('GHPASS'),
        two_factor_callback=two_fa
    )

    for repo in EXTRAS:
        _repo = repo.split('/')
        if len(_repo) is not 2:
            continue

        org = repo.split('/')[0]
        repository = repo.split('/')[1]
        gh_repo = api.repository(org, repository)

        reqs[repo] = {}
        contents = gh_repo.contents('/', return_as=dict)
        for entry, content in contents:
            if content.type is not "dir":
                continue

            req = gh_repo.file_contents("/{}/requirements.txt".format(entry))
            reqs[repo][entry] = req.decoded

    return reqs


def get_files(fname):
    matches = []
    for root, dirnames, filenames in os.walk('.'):
        for filename in fnmatch.filter(filenames, fname):
            matches.append(os.path.join(root, filename))

    return matches


def get_local_contents(files):
    local_reqs = {}
    for fname in files:
        integration = fname.split('/')[0]
        with open(fname) as f:
            content = f.readlines()

        local_reqs[integration] = content

    return local_reqs


def process_requirements(reqs, fname):
    SPECIFIERS = ['==', '!=' '<=', '>=', '<', '>']

    print "processing... {}".format(fname)
    with open(fname) as f:
        content = f.readlines()

    for line in content:
        line = "".join(line.split())
        for specifier in SPECIFIERS:
            idx = line.find(specifier)
            if idx < 0:
                continue

            req = line[:idx]
            specifier = line[idx:]

            if req in reqs and reqs[req][0] != specifier:
                # version mismatch
                print "There's a version mismatch with {req} " \
                    " {spec} and {prev_spec} defined in {src}.".format(
                        req=req,
                        spec=specifier,
                        prev_spec=reqs[req][0],
                        src=reqs[req][1]
                    )
                sys.exit(ERR)
            elif req not in reqs:
                reqs[req] = (specifier, fname)
                break


requirements = {}
files = get_files('requirements.txt')

for f in files:
    process_requirements(requirements, f)

print "No requirement version conflicts found. Looking good... ;)"
for req, spec in requirements.iteritems():
    print "{req}{spec} first found in {fname}".format(
        req=req,
        spec=spec[0],
        fname=spec[1]
    )

sys.exit(OK)
