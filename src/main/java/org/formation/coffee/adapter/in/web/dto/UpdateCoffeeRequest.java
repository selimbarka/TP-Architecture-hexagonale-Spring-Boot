package org.formation.coffee.adapter.in.web.dto;

import org.jspecify.annotations.Nullable;

/**
 * Mise à jour partielle : un champ absent reste inchangé.
 */
public record UpdateCoffeeRequest(@Nullable String name, @Nullable Integer price) {
}
