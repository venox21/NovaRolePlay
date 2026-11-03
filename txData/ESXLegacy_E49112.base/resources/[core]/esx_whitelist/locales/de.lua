-- SPDX-License-Identifier: GPL-3.0-only
-- Copyright (C) 2022-2026 ESX Framework

return {
    ['whitelist_title'] = 'Whitelist',

    ['admin_only'] = 'Dieser Server ist derzeit nur für Administratoren zugänglich.',
    ['not_whitelisted'] = 'Du stehst nicht auf der Whitelist dieses Servers.',
    ['discord_required'] = 'Ein verknüpfter Discord-Account ist erforderlich, um beizutreten.',
    ['discord_role_required'] = 'Dir fehlt die erforderliche Discord-Rolle, um dem Server beizutreten.',
    ['discord_server_required'] = 'Du musst Mitglied auf unserem Discord-Server sein, um beizutreten.',
    ['discord_unavailable'] = 'Die Überprüfung ist vorübergehend nicht verfügbar. Bitte versuche es gleich erneut.',
    ['verification_timeout'] = 'Zeitüberschreitung bei der Überprüfung. Bitte versuche es erneut.',
    ['verification_error'] = 'Interner Fehler bei der Überprüfung. Bitte versuche es erneut.',

    ['checking_whitelist'] = 'Whitelist wird überprüft...',
    ['checking_discord_membership'] = 'Discord-Mitgliedschaft wird überprüft...',
    ['verifying_authorization'] = 'Berechtigung wird geprüft...',

    ['command_no_permission'] = 'Du hast keine Berechtigung für diesen Befehl.',
    ['command_usage'] = 'Verwendung: %s [%s|%s|%s|%s [%s]|%s <id>|%s <identifier> [type]|%s <identifier> [type]]',
    ['command_usage_test'] = 'Verwendung: %s %s <serverId>',
    ['command_usage_add'] = 'Verwendung: %s %s <identifier> [whitelist|admin_only|bypass]',
    ['command_usage_remove'] = 'Verwendung: %s %s <identifier> [whitelist|admin_only|bypass]',
    ['command_identifier_added'] = '%s zur Liste %s in der Datenbank hinzugefügt.',
    ['command_identifier_removed'] = '%s aus der Liste %s in der Datenbank entfernt.',
    ['command_invalid_identifier'] = 'Ungültiges Identifier-Format: %s',
    ['panel_only_in_game'] = 'Das Menü kann nur im Spiel geöffnet werden.',
    ['runtime_reloaded'] = 'Laufzeitkonfiguration und Cache aus Datenbank neu geladen.',
    ['runtime_reloaded_fallback'] = 'Laufzeitkonfiguration Fallback wiederhergestellt.',
    ['discord_cache_cleared'] = 'Discord-Verifizierungscache geleert.',
    ['no_online_player'] = 'Kein Spieler mit Server-ID %d online.',
    ['player_left_before_check'] = 'Spieler hat das Spiel vor Abschluss der Prüfung verlassen.',
    ['command_status'] = 'Whitelist: %s | Modus=%s (%s) | Nur Admins=%s',
    ['command_status_discord'] = 'Discord: %s | Anfragen=%d CacheHits=%d Shared=%d RateLimits=%d Fehler=%d',
    ['command_status_decisions'] = 'Entscheidungen: Gesamt=%d Erlaubt=%d Abgelehnt=%d | AdminCache=%d Einträge',
    ['command_cache_stats'] = 'Discord Cache: %d Einträge | Admin Cache: %d Einträge | Warteschlange: %d (Aktiv %d)',
    ['command_test_result'] = 'Test für %s [%d]: %s | Methode=%s | Grund=%s | Identifier=%s',
    ['command_status_format'] = 'Whitelist: %s | Modus=%s (%s) | Nur Admins=%s',
}