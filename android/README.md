# network.passkeys.client

network.passkeys.client

## Installation

```sh
implementation 'network.passkeys.client:1.0.2'
```

## Usage

```kotlin
...

import network.passkeys.client.Passkeys

...

class MainActivity : AppCompatActivity() {
    private lateinit var passkeys: Passkeys

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val rootLayout = findViewById<RelativeLayout>(R.id.root_layout)

        passkeys = Passkeys(this).apply {
            visibility = View.GONE
            layoutParams = RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT,
                RelativeLayout.LayoutParams.MATCH_PARENT
            )
        }
        passkeys.setAppId("test")
        rootLayout.addView(passkeys)

        val connectButton = Button(this).apply {
            text = "Connect"
            layoutParams = RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.WRAP_CONTENT,
                RelativeLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                addRule(RelativeLayout.CENTER_IN_PARENT)
            }
            setOnClickListener {
                passkeys.callMethod("connect", null) { result ->
                    result.fold(
                        onSuccess = { println(it) },
                        onFailure = { println(it) }
                    )
                }
            }
        }

        rootLayout.addView(connectButton)
    }
}
```

## Publishing

We are publishing to [maven central](httos://central.sonatype.com). You will need this in your `gradle.properties`

```kotlin
mavenCentralUsername=[username]
mavenCentralPassword=[token]
android.useAndroidX=true
signing.gnupg.executable=gpg
signing.gnupg.useAgent=true
```

## License

MIT