# Secure Chat (iOS version)

Demo project of DIM Client, just for study purpose.

Dependencies:

- [<b>DIM Client</b> (demo-objc)](https://github.com/dimchat/demo-objc)
	- [DIM SDK (sdk-objc)](https://github.com/dimchat/sdk-objc)
		- [DIM Core (core-objc)](https://github.com/dimchat/core-objc)
			- [Message Module (dkd-objc)](https://github.com/dimchat/dkd-objc)
			- [Account Module (mkm-objc)](https://github.com/dimchat/mkm-objc)
	- [Star Trek](https://github.com/moky/StarTrek)
		- [State Machine](https://github.com/moky/FiniteStateMachine)
		- [Object Kits](https://github.com/moky/ObjectKey)
- [<b>Network Module</b> (moky/StarGate)](https://github.com/moky/StarGate)
	- [Tencent/mars](https://github.com/Tencent/mars)

## Getting started

### 0. Download source codes and requirements

```
cd GitHub/
mkdir dimchat; cd dimchat/

# demo source codes
git clone https://github.com/dimchat/demo-ios.git

# requirements
git clone https://github.com/dimchat/demo-objc.git

cd ..; mkdir moky; cd moky/
git clone https://github.com/moky/StarGate.git
```

### 1. Test in simulators

```
cd GitHub/dimchat/demo-ios/Sechat/

# install requirements
pod install --repo-update
```

after all pods installed, open `GitHub/dimchat/demo-ios/Sechat/Sechat.xcworkspace`

### 2. Test in iOS devices

* Download source codes of `Tencent/mars`:

```
cd GitHub/
mkdir Tencent; cd Tencent/

git clone https://github.com/Tencent/mars.git
```

* Edit building script `build_ios.py` to enable bitcode for iOS devices:

```
cd GitHub/Tencent/mars/mars

vi build_ios.py
#
# search 'ENABLE_BITCODE=0', modify it to 'ENABLE_BITCODE=1'
#

python build_ios.py
#
# choose '1. Clean && build mars.'
# after building mars successfully,
#     copy 'Tencent/mars/mars/cmake_build/iOS/Darwin.out/mars.framework'
#     to replace 'moky/StarGate/MarsGate/mars.framework'
#
```

then open `GitHub/dimchat/demo-ios/Sechat/Sechat.xcworkspace`

--
<i>Edited by [Alber Moky](https://twitter.com/AlbertMoky) @ 2023-3-25</i>