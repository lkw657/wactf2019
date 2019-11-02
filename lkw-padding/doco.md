Challenge Data:

|metadata | <> |
|--- | --- |
|Company |   |
|Developer Name(s) | lkw |
|Contact | lkw (slack) |
|Challenge Category | Crypto |
|Challenge Tier | 3 |

|Player facing | <> |
|--- | --- |
|Challenge Name |  |
|Challenge Description | We intercepted these messages to the auth server runnin on port 3300. Can you decrypt them and find the flag? 1f8b08002c26bc5d00ff6310b0d29821639f21f526ec6cc1a41733ec2acface30b5be7dcd46f79704f22e7a63ade1332322f36ae147a1cd2f368be93d3fb6d005980bba932000000 1f8b08006326bc5d00ff6310e88ebc724ee362fed2f84782d67fef33702ca9a93995b42c2ad7b0f3dab28ac96e2f67ac987dfcbcd7c9bf5f67ca3af586643add6c707da6c5716e7393f0d10f5384f6060200816b8a2242000000 1f8b08003f25bc5d00ff6310e82a70b54f5c2a7223e581e65fd99513e24bc3ce5eabadd5cedfb64b9a79b6c1db98ce9f95e18cf9260d917969ab73a6bacce759fda2e3aa8f8163e581fa2bdf0d1d660100e3496d6a42000000|
|Challenge Hint 1 | Do the strings have anything in common? | 
|Challenge Hint 2 | What happens if you change the last byte? |
|Challenge Hint 3 | Check the basic auth header in one of the HTTP requests |

|Admin Facing | <> |
|--- | --- |
|Challenge Flag| WACTF3{omen-leotard-unjustly-gloomily} |
|Challenge Vuln| Padding oracle |

Challenge PoC
---
See solvePadding.py
