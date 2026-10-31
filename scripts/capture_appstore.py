#!/usr/bin/env python3
"""Capture real Turkish iOS screens. Run after installing Kamus on the simulator."""
import argparse, json, subprocess, time
from pathlib import Path
from urllib.parse import quote
p=argparse.ArgumentParser();p.add_argument('--udid',required=True);p.add_argument('--family',choices=['iphone','ipad'],required=True);a=p.parse_args()
def run(*args,check=True): return subprocess.run(args,check=check,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
def tap(label,kind=None,check=True):
 args=['axe','tap','--label',label,'--udid',a.udid,'--wait-timeout','2']
 if kind: args += ['--element-type',kind]
 return run(*args,check=check)
root=Path(__file__).resolve().parent.parent;out=root/'screenshots/raw/tr'/a.family;out.mkdir(parents=True,exist_ok=True)
run('xcrun','simctl','ui',a.udid,'appearance','light')
run('xcrun','simctl','status_bar',a.udid,'override','--time','9:41','--dataNetwork','wifi','--wifiMode','active','--wifiBars','3','--batteryState','charged','--batteryLevel','100')
for word in ['ilham','keşif','merak']:
 run('xcrun','simctl','openurl',a.udid,'kamus://search?q='+quote(word));time.sleep(1)
 tap('Open',check=False);tap('Favorilere ekle',check=False)
for label,name in [(None,'01-search'),('Günün Kelimesi','02-daily'),('Favoriler','03-favorites'),('Geçmiş','04-history')]:
 if label:
  if a.family == 'ipad':
   run('axe','tap','-x',str({'Günün Kelimesi':450,'Favoriler':576,'Geçmiş':671}[label]),'-y','54','--udid',a.udid)
  else: tap(label,'RadioButton')
 time.sleep(.8)
 run('axe','screenshot','--udid',a.udid,'--output',str(out/(name+'.png')))
 print(name,flush=True)
