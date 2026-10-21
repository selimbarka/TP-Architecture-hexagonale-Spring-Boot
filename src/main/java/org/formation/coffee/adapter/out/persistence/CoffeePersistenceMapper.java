package org.formation.coffee.adapter.out.persistence;

import org.formation.coffee.domain.model.Coffee;
import org.formation.coffee.domain.model.CoffeeId;
import org.formation.coffee.domain.model.Price;
import org.formation.coffee.domain.model.Review;
import org.formation.coffee.domain.model.ReviewId;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import java.util.List;
import java.util.Objects;

@Mapper
interface CoffeePersistenceMapper {

    default Coffee toDomain(CoffeeJpaEntity entity) {
        return Coffee.reconstitute(
                new CoffeeId(Objects.requireNonNull(entity.getId(), "a stored coffee has an id")),
                entity.getName(),
                new Price(entity.getPrice()),
                toDomainReviews(entity.getReviews()));
    }

    List<Review> toDomainReviews(List<ReviewJpaEntity> entities);

    Review toDomainReview(ReviewJpaEntity entity);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "reviews", ignore = true)
    CoffeeJpaEntity toNewEntity(Coffee coffee);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "reviews", ignore = true)
    void updateEntity(Coffee coffee, @MappingTarget CoffeeJpaEntity entity);

    default ReviewId toReviewId(Long id) {
        return new ReviewId(id);
    }

    default int toAmount(Price price) {
        return price.amount();
    }
}
