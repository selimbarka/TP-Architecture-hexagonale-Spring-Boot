package org.formation.coffee.adapter.in.web.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Seule la forme de la requête est validée ici ; les règles métier (plage de prix, longueur du nom)
 * appartiennent au domaine.
 */
public record CreateCoffeeRequest(@NotBlank String name, @NotNull Integer price) {
}
