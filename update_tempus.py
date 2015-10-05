#!/usr/bin/python

import os
import requests
import yaml
import shutil
import subprocess
import errno

from zipfile import ZipFile
from tempfile import TemporaryFile, mkdtemp

def log(s):
    print '[Tempus] {}'.format(s)

def downloadSPBuild(version, fileName):
    url = 'http://build.affecta.net/job/Source.Python/{}/artifact/release/{}'.format(version, fileName)
    return requests.get(url, stream=True)

def getSPBuildFileName(version):
    url = 'http://build.affecta.net/job/Source.Python/{}/api/json'.format(version)
    result = requests.get(url).json()
    for a in result['artifacts']:
        if a['fileName'].startswith('source-python-tf2-'):
            return a['fileName']
    else:
        raise RuntimeError('TF2 SP build for version \'{}\' not found.'.format(version))

def downloadSPPatches(path, url, auth):
    url = url + 'tempus_builds/files/sp_tempus_patches.zip'
    fd = TemporaryFile()
    r = requests.get(url, auth=auth, stream=True)
    for block in r.iter_content(1024):
        fd.write(block)
    with ZipFile(fd, 'r') as z:
        z.extractall(path)

def main():
    SRCDS_PATH = '/srv/srcds/tf'
    ADDONS_PATH = os.path.join(SRCDS_PATH, 'addons')
    SP_PATH = os.path.join(ADDONS_PATH, 'source-python')
    TEMPUS_PATH = os.path.join(
        ADDONS_PATH, 'source-python', 'plugins', 'tempus_loader')
    CFG_PATH = os.path.join(TEMPUS_PATH, 'local', 'cfg', 'api.yml')
    TEMPUS_VERSION_PATH = os.path.join(TEMPUS_PATH, 'tempus', 'tempus', 'version')
    SP_VERSION_PATH = os.path.join(
        ADDONS_PATH, 'source-python', 'packages', 'source-python', 'core',
        'version.py')

    tempusFullInstall = False
    if os.path.exists(os.path.realpath(TEMPUS_VERSION_PATH)):
        with open(TEMPUS_VERSION_PATH, 'rb') as f:
            tempusVersion = int(f.read().strip())
    else:
        tempusFullInstall = True

    spFullInstall = False
    if os.path.exists(SP_VERSION_PATH):
        with open(SP_VERSION_PATH, 'rb') as f:
            for line in f.readlines():
                if line.startswith('VERSION ='):
                    spVersion = int(line[10:].strip().strip("'"))
                    break
            else:
                raise RuntimeError('Could not find SP version.')
    else:
        spFullInstall = True

    with open(CFG_PATH, 'rb') as f:
        cfg = yaml.safe_load(f)
    url = '{}{}/'.format(cfg['hostname'], cfg['deployment'])
    auth = (cfg['username'], cfg['password'])

    log('Checking for updates...')
    r = requests.get(url + 'tempus_builds/latest_version', auth=auth)
    latestVersion = int(r.json()['version'])

    if not tempusFullInstall and latestVersion == tempusVersion:
        log('Already up to date.')
        return

    tfd = TemporaryFile()

    r = requests.get(url + 'tempus_builds/files/tempus{}.zip'.format(latestVersion), auth=auth, stream=True)
    if not r.ok:
        raise RuntimeError('Failed to fetch Tempus.')
    for block in r.iter_content(1024):
        tfd.write(block)

    tTempusPath = mkdtemp()
    with ZipFile(tfd, 'r') as z:
        z.extractall(tTempusPath)

    with open(os.path.join(tTempusPath, 'tempus_loader', 'tempus', 'tempus', 'SP_VERSION')) as f:
        requiredSPVersion = int(f.read().strip())

    needSPUpdate = False
    if spFullInstall is True or requiredSPVersion != spVersion:
        needSPUpdate = True
        spfd = TemporaryFile()
        fileName = getSPBuildFileName(requiredSPVersion)
        log('Fetching SP version {}: {}...'.format(requiredSPVersion, fileName))
        r = downloadSPBuild(requiredSPVersion, fileName)
        for block in r.iter_content(1024):
            spfd.write(block)
        tSPPath = mkdtemp()
        with ZipFile(spfd, 'r') as z:
            z.extractall(tSPPath)
        log('Applying SP patches...')
        downloadSPPatches(tSPPath, url, auth)

    if spFullInstall:
        log('Installing SP from scratch...')
        subprocess.call([
            'rsync',
            '-r',
            os.path.join(tSPPath) + '/',
            SRCDS_PATH
        ])
        shutil.rmtree(tSPPath)
    elif needSPUpdate:
        log('Updating SP...')
        for d in ['bin', 'data', 'packages', 'Python3']:
            dest = os.path.join(SP_PATH, d)
            try:
                shutil.rmtree(dest)
            # path does not exist
            except OSError:
                pass
            shutil.copytree(os.path.join(tSPPath, 'addons', 'source-python', d), dest)
        for d in ['resource', 'sound']:
            dest = os.path.join(SRCDS_PATH, d, 'source-python')
            try:
                shutil.rmtree(dest)
            # path does not exist
            except OSError:
                pass
            shutil.copytree(os.path.join(tSPPath, d, 'source-python'), dest)

        shutil.rmtree(tSPPath)

    if tempusFullInstall:
        log('Installing Tempus from scratch...')
        subprocess.call([
            'rsync',
            '-r',
            os.path.join(tTempusPath, 'tempus_loader/'),
            os.path.join(SP_PATH, 'plugins/tempus_loader')
        ])
    else:
        log('Updating Tempus...')
        up = os.path.join(TEMPUS_PATH, 'local', 'updates')
        if not os.path.exists(up):
            os.makedirs(up)

        tUpdatePath = os.path.join(up, str(latestVersion))
        if os.path.exists(tUpdatePath):
            shutil.rmtree(tUpdatePath)
        shutil.copytree(tTempusPath, tUpdatePath)

        tempusLibsPath = os.path.join(TEMPUS_PATH, 'tempus')

        try:
            os.unlink(tempusLibsPath)
        except OSError as e:
            if e.errno == errno.ENOENT:
                pass
            elif e.errno == errno.EISDIR:
                # if tempus has not been updated since initial deploy,
                # `tempus_loader/tempus` will be a dir instead of a symlink
                shutil.rmtree(tempusLibsPath)
            else:
                raise
        os.symlink(os.path.join(tUpdatePath, 'tempus_loader', 'tempus'),
                   tempusLibsPath)
        shutil.rmtree(tTempusPath)
    log('Update complete.')

main()
