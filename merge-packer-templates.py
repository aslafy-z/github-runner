#!/usr/bin/python3

import argparse
import json
from typing import Dict, List, Any, Union

parser = argparse.ArgumentParser('merge-packer-templates')
parser.add_argument('--inject-env', '-e',
                    dest='inject_env',
                    default=True,
                    help='Inject /etc/environment if not using sudo')
parser.add_argument('--remove-reboot', '-x',
                    dest='remove_reboot',
                    default=True,
                    help='Remove the reboot provisioner and fixup the pause/timeout')
parser.add_argument('--upstream', '-u',
                    dest='upstream_template_path',
                    required=True,
                    type=argparse.FileType('rt'),
                    help='The virtual-environments packer template')
parser.add_argument('--github-runner', '-g',
                    dest='runner_template_path',
                    required=True,
                    type=argparse.FileType('rt'),
                    help='The github-runner base template')
parser.add_argument('--add-provisioners', '-a',
                    dest='add_provisioners_path',
                    required=True,
                    type=argparse.FileType('rt'),
                    help='The add-provisioners file. Scripts to be added to main body of provisioner scripts, '
                         'just before the "clean" script.')
parser.add_argument('--replace-scripts', '-r',
                    dest='replace_scripts_path',
                    type=argparse.FileType('rt'),
                    help='The replace-scripts file. Scripts to be replaced in provisioners')
parser.add_argument('--replace-inline', '-i',
                    dest='replace_inline_path',
                    default='aws-replace-inline.json',
                    type=argparse.FileType('rt'),
                    help='The replace-inline file. Inline shell commands to be replaced in provisioners')
parser.add_argument('--target', '-t',
                    dest='target_template_path',
                    required=True,
                    type=argparse.FileType('wt'),
                    help='The target packer template')

if __name__ == '__main__':
    args = parser.parse_args()
    target_template: Dict[str, Union[List[Any], Any]] = {}
    upstream_template = json.load(args.upstream_template_path)
    runner_template = json.load(args.runner_template_path)
    add_provisioners_template = json.load(args.add_provisioners_path)
    replace_scripts = None
    if args.replace_scripts_path:
        replace_scripts = json.load(args.replace_scripts_path)
    replace_inline = json.load(args.replace_inline_path)

    target_template['variables'] = runner_template['variables']
    target_template['sensitive-variables'] = runner_template['sensitive-variables']
    target_template['builders'] = runner_template['builders']
    target_template['provisioners'] = runner_template['provisioners'] + upstream_template['provisioners']
    if 'post-processors' in runner_template:
        target_template['post-processors'] = runner_template['post-processors']

    for pr in target_template['provisioners']:
        if 'scripts' in pr and replace_scripts is not None:
            pr['scripts'] = [r['replace'] if s == r['find'] else s for s in pr['scripts'] for r in replace_scripts]
        if 'inline' in pr:
            for s in pr['inline']:
                for r in replace_inline:
                    if s == r['find']:
                        pr['inline'] = r['replace']
                    else:
                        continue
        if args.inject_env:
            if 'execute_command' in pr:
                if not 'sudo' in pr['execute_command']:
                    if 'sh -c' in pr['execute_command']:
                        pr['execute_command'] = pr['execute_command'].replace('sh -c \'{{ .Vars }}',
                                                                              'bash -c \'source /etc/environment '
                                                                              '&& {{ .Vars }}')

    for idx, pr in enumerate(target_template['provisioners']):
        if 'scripts' in pr \
                and '{{template_dir}}/scripts/installers/cleanup.sh' in pr['scripts']:
            target_template['provisioners'][idx:idx] = add_provisioners_template['provisioners']
            break
    target_template['provisioners'] = [pr for pr
                                       in target_template['provisioners']
                                       if not (args.remove_reboot
                                               and 'scripts' in pr
                                               and ('{{template_dir}}/scripts/base/reboot.sh'
                                                    in pr['scripts']
                                                    or '{{template_dir}}/scripts/installers/homebrew-validate.sh'
                                                    in pr['scripts']))
                                       and not ('destination' in pr
                                                and ('{{template_dir}}/Ubuntu2004-README.md'
                                                     in pr['destination']))]

    target_template['provisioners'].pop()

    json.dump(target_template, args.target_template_path, indent=4)
