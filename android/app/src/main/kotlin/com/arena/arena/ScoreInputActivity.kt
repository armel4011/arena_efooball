package com.arena.arena

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.CheckBox
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.Toast

/**
 * Mini-dialogue de saisie du SCORE, ouvert depuis le bouton « Score » de la
 * notif de contrôle (ArenaRecorderService). REPLI UNIVERSEL du bouton flottant :
 * marche même là où la superposition est bloquée (Pixel 9 / Android 15). C'est
 * l'Étape B — même scénario que le bouton « Score » de l'overlay, mais porté par
 * la notification.
 *
 * Vues Android natives (pas Flutter) : le dialogue s'ouvre instantanément
 * par-dessus le jeu, sans démarrer de moteur Flutter. Le score saisi repart vers
 * [ArenaRecorderService] (ACTION_SUBMIT_SCORE), qui le forwarde à Dart via
 * `onScoreSubmitted` — Dart mappe mon/adverse → score1/score2 selon le rôle,
 * SOUMET le score et SCELLE la vidéo (mêmes garde-fous que l'overlay).
 *
 * Thème flottant translucide réutilisé de [RoomCodeInputActivity].
 */
class ScoreInputActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_score_input)

        val my = findViewById<EditText>(R.id.score_my)
        val opp = findViewById<EditText>(R.id.score_opp)
        val viaPen = findViewById<CheckBox>(R.id.score_via_pen)
        val penRow = findViewById<LinearLayout>(R.id.score_pen_row)
        val penMy = findViewById<EditText>(R.id.score_pen_my)
        val penOpp = findViewById<EditText>(R.id.score_pen_opp)

        // Les champs de tirs au but n'apparaissent que si la case est cochée
        // (comme le volet pénaltys de l'overlay). Le natif ne connaît pas le
        // format (poule vs élimination) : Dart IGNORE les pénaltys en poule.
        viaPen.setOnCheckedChangeListener { _, checked ->
            penRow.visibility = if (checked) View.VISIBLE else View.GONE
        }

        my.requestFocus()

        findViewById<Button>(R.id.score_submit).setOnClickListener {
            val m = my.text?.toString()?.trim()?.toIntOrNull()
            val o = opp.text?.toString()?.trim()?.toIntOrNull()
            if (m == null || o == null || m < 0 || m > 99 || o < 0 || o > 99) {
                Toast.makeText(this, "Score invalide (0 à 99).", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            var pm: Int? = null
            var po: Int? = null
            val pen = viaPen.isChecked
            if (pen) {
                if (m != o) {
                    Toast.makeText(
                        this,
                        "Tirs au but : le score doit être à égalité.",
                        Toast.LENGTH_SHORT,
                    ).show()
                    return@setOnClickListener
                }
                pm = penMy.text?.toString()?.trim()?.toIntOrNull()
                po = penOpp.text?.toString()?.trim()?.toIntOrNull()
                if (pm == null || po == null || pm < 0 || po < 0 || pm > 30 || po > 30) {
                    Toast.makeText(this, "Tirs au but invalides (0 à 30).", Toast.LENGTH_SHORT).show()
                    return@setOnClickListener
                }
                if (pm == po) {
                    Toast.makeText(
                        this,
                        "Les tirs au but ne peuvent pas être à égalité.",
                        Toast.LENGTH_SHORT,
                    ).show()
                    return@setOnClickListener
                }
            }
            try {
                startService(
                    Intent(this, ArenaRecorderService::class.java).apply {
                        action = ArenaRecorderService.ACTION_SUBMIT_SCORE
                        putExtra(ArenaRecorderService.EXTRA_SCORE_MY, m)
                        putExtra(ArenaRecorderService.EXTRA_SCORE_OPP, o)
                        putExtra(ArenaRecorderService.EXTRA_SCORE_VIA_PEN, pen)
                        if (pen) {
                            putExtra(ArenaRecorderService.EXTRA_SCORE_PEN_MY, pm!!)
                            putExtra(ArenaRecorderService.EXTRA_SCORE_PEN_OPP, po!!)
                        }
                    },
                )
                Toast.makeText(this, "Score envoyé", Toast.LENGTH_SHORT).show()
            } catch (e: Exception) {
                // Service mort (enregistrement déjà arrêté) : ne pas laisser le
                // joueur croire que le score est parti.
                Toast.makeText(this, "Envoi impossible — ouvre ARENA", Toast.LENGTH_LONG).show()
            }
            finish()
        }

        findViewById<Button>(R.id.score_cancel).setOnClickListener { finish() }
    }
}
