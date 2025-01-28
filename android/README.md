# network.passkeys.client

network.passkeys.client

## Installation

```sh
implementation 'network.passkeys:client:1.0.5'
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

        val errorMessageTextView = TextView(this).apply {
            visibility = View.GONE
            setTextColor(getColor(android.R.color.holo_red_dark))
            layoutParams = RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.WRAP_CONTENT,
                RelativeLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                addRule(RelativeLayout.CENTER_HORIZONTAL)
                addRule(RelativeLayout.ALIGN_PARENT_TOP)
                topMargin = 50
            }
        }
        rootLayout.addView(errorMessageTextView)

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
            isEnabled = false
        }
        rootLayout.addView(connectButton)

        passkeys.isLoading.observe(this, Observer { isLoading ->
            val errorMessage = passkeys.loadingErrorMessage
            connectButton.isEnabled = !isLoading && errorMessage == null
            if (errorMessage != null) {
                errorMessageTextView.text = errorMessage
                errorMessageTextView.visibility = View.VISIBLE
            } else {
                errorMessageTextView.visibility = View.GONE
            }
        })
    }

    override fun onPause() {
        super.onPause()
        passkeys.onPause()
    }

    override fun onResume() {
        super.onResume()
        passkeys.onResume()
    }

    override fun onDestroy() {
        super.onDestroy()
        passkeys.onDestroy()
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