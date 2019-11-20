import pathlib

from pydo import *

this_dir = pathlib.Path(__file__).parent

package = {
    'requires': ['net'],
    'sysroot_debs': [],
    'root_debs': ['wget', 'curl'],
    'target': this_dir / 'balenamigration.tar.gz',
    'install': ['{chroot} {stage} /bin/systemctl reenable balenamigration.service'],
}

stage = this_dir / 'stage'
service = this_dir / 'balenamigration.service'
scriptmigration = this_dir / 'balenamigration.sh'
scriptnettool = this_dir / 'nettool.sh'

@command(produces=[package['target']], consumes=[service])
def build():
    call([
        f'rm -rf --one-file-system {stage}',

        f'mkdir -p {stage}/etc/systemd/system',
        f'mkdir -p {stage}/opt/balenamigration/',
        f'cp {service} {stage}/etc/systemd/system/',
        f'cp {scriptmigration} {stage}/opt/balenamigration/',
        f'cp {scriptnettool} {stage}/opt/balenamigration/',

        f'tar -C {stage} -czf {package["target"]} .',
    ])


@command()
def clean():
    call([
        f'rm -rf --one-file-system {stage} {package["target"]}',
    ])
