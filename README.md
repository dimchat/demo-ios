# Secure Chat (iOS version)

Demo project of DIM Client, just for study purpose.

Dependencies:

- [DIM Client (client-objc)](https://github.com/dimchat/client-objc)
	- [DIM Core (core-objc)](https://github.com/dimchat/core-objc)
		- [Message Module (dkd-objc)](https://github.com/dimchat/dkd-objc)
		- [Account Module (mkm-objc)](https://github.com/dimchat/mkm-objc)
	- [Connection Module (moky/StarGate)](https://github.com/moky/StarGate)
		- [Tencent/mars](https://github.com/Tencent/mars)
	- [Finite State Machine](https://github.com/moky/FiniteStateMachine)

## Getting started

### 0. Download source codes and requirements

```
cd GitHub/
mkdir dimchat; cd dimchat/

# source codes
git clone https://github.com/dimchat/client-ios.git

# requirements
git clone https://github.com/dimchat/client-objc.git
git clone https://github.com/dimchat/core-objc.git
git clone https://github.com/dimchat/dkd-objc.git
git clone https://github.com/dimchat/mkm-objc.git

cd ..; mkdir moky; cd moky/
git clone https://github.com/moky/StarGate.git
```

### 1. Test in simulators

Just open `dimchat/client-ios/Sechat/Sechat.xcodeproj`

### 2. Test in iOS devices

* Download source codes of `Tencent/mars`:

```
cd GitHub/
mkdir Tencent; cd Tencent/

git clone https://github.com/Tencent/mars.git
```

* Edit building script `build_ios.py` to enable bitcode for iOS devices:

```
cd GitHub/
cd Tencent/mars/mars

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

then open `dimchat/client-ios/Sechat/Sechat.xcodeproj`
