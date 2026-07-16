package com.arena.arena

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.Toast

/**
 * Mini-dialogue de saisie du code room, ouvert depuis la pastille « Envoyer »
 * de la notif de contrôle (côté HOME).
 *
 * Pourquoi une activité plutôt que la réponse directe d'une notification : le
 * champ de saisie inline n'existe que sur une action STANDARD, et Android n'y
 * autorise ni icône (≥ N) ni couleur — on ne pouvait donc pas l'aligner sur les
 * pastilles colorées. Thème flottant translucide : eFootball reste visible
 * derrière, le joueur ne quitte pas vraiment son jeu.
 *
 * Vues Android natives (pas Flutter) : le dialogue doit s'ouvrir instantanément
 * par-dessus le jeu, sans démarrer de moteur Flutter.
 *
 * Le code saisi repart vers [ArenaRecorderService] (ACTION_SUBMIT_CODE), qui le
 * forwarde à Dart via `onRoomCodeSubmitted` — même chemin qu'avant.
 */
class RoomCodeInputActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_room_code_input)
        // Clavier ouvert d'emblée : le joueur vient de lire le code dans
        // eFootball, il a une seule chose à faire ici.
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE)

        val field = findViewById<EditText>(R.id.room_code_field)
        field.requestFocus()

        findViewById<Button>(R.id.room_code_submit).setOnClickListener {
            val code = field.text?.toString()?.trim().orEmpty()
            if (code.isEmpty()) {
                field.error = "Saisis le code"
                return@setOnClickListener
            }
            try {
                startService(
                    Intent(this, ArenaRecorderService::class.java).apply {
                        action = ArenaRecorderService.ACTION_SUBMIT_CODE
                        putExtra(ArenaRecorderService.EXTRA_TYPED_CODE, code)
                    },
                )
                Toast.makeText(this, "Code envoyé", Toast.LENGTH_SHORT).show()
            } catch (e: Exception) {
                // Service mort (enregistrement déjà arrêté) : ne pas laisser le
                // joueur croire que le code est parti.
                Toast.makeText(this, "Envoi impossible — ouvre ARENA", Toast.LENGTH_LONG).show()
            }
            finish()
        }

        findViewById<Button>(R.id.room_code_cancel).setOnClickListener { finish() }
    }
}
