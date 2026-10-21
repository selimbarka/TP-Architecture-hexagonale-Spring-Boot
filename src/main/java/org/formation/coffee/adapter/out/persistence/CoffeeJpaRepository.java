package org.formation.coffee.adapter.out.persistence;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

interface CoffeeJpaRepository extends JpaRepository<CoffeeJpaEntity, Long> {

    /**
     * Charge tous les cafés avec leurs avis en une seule requête.
     */
    @EntityGraph(attributePaths = "reviews")
    List<CoffeeJpaEntity> findAllByOrderByIdAsc();

    @EntityGraph(attributePaths = "reviews")
    Optional<CoffeeJpaEntity> findWithReviewsById(Long id);
}
