#!/usr/bin/env bash
# A lancer depuis la racine du projet coffee-hexa-simple :  bash create-classes.sh
set -e
B=src/main/java/org/formation/coffee

mkdir -p $B/domain/model $B/domain/exception \
  $B/application/port/in $B/application/port/out $B/application/service \
  $B/adapter/in/web/dto $B/adapter/out/persistence $B/adapter/out/transaction \
  $B/config

############################ DOMAINE : exceptions ############################
cat > $B/domain/exception/DomainException.java <<'EOF'
package org.formation.coffee.domain.exception;

/**
 * Type de base de toutes les exceptions levées par le domaine.
 */
public abstract class DomainException extends RuntimeException {

    protected DomainException(String message) {
        super(message);
    }
}
EOF

cat > $B/domain/exception/DomainValidationException.java <<'EOF'
package org.formation.coffee.domain.exception;

/**
 * Levée quand une valeur ou une opération violerait un invariant métier.
 */
public class DomainValidationException extends DomainException {

    public DomainValidationException(String message) {
        super(message);
    }
}
EOF

cat > $B/domain/exception/CoffeeNotFoundException.java <<'EOF'
package org.formation.coffee.domain.exception;

import org.formation.coffee.domain.model.CoffeeId;

/**
 * Levée quand aucun café n'existe pour l'identifiant demandé.
 */
public class CoffeeNotFoundException extends DomainException {

    private final CoffeeId coffeeId;

    public CoffeeNotFoundException(CoffeeId coffeeId) {
        super("Coffee " + coffeeId.value() + " not found");
        this.coffeeId = coffeeId;
    }

    public CoffeeId getCoffeeId() {
        return coffeeId;
    }
}
EOF

############################ DOMAINE : modèle ############################
cat > $B/domain/model/Price.java <<'EOF'
package org.formation.coffee.domain.model;

import org.formation.coffee.domain.exception.DomainValidationException;

/**
 * Prix d'un café, toujours compris entre {@link #MIN} et {@link #MAX} inclus.
 */
public record Price(int amount) {

    public static final int MIN = 0;
    public static final int MAX = 200;

    public Price {
        if (amount < MIN || amount > MAX) {
            throw new DomainValidationException(
                    "Price must be between %d and %d, got %d".formatted(MIN, MAX, amount));
        }
    }
}
EOF

cat > $B/domain/model/CoffeeId.java <<'EOF'
package org.formation.coffee.domain.model;

import org.formation.coffee.domain.exception.DomainValidationException;

/**
 * Identité d'un {@link Coffee}.
 */
public record CoffeeId(long value) {

    public CoffeeId {
        if (value <= 0) {
            throw new DomainValidationException("Coffee id must be positive, got " + value);
        }
    }
}
EOF

cat > $B/domain/model/ReviewId.java <<'EOF'
package org.formation.coffee.domain.model;

import org.formation.coffee.domain.exception.DomainValidationException;

/**
 * Identité d'un {@link Review}.
 */
public record ReviewId(long value) {

    public ReviewId {
        if (value <= 0) {
            throw new DomainValidationException("Review id must be positive, got " + value);
        }
    }
}
EOF

cat > $B/domain/model/Review.java <<'EOF'
package org.formation.coffee.domain.model;

import org.formation.coffee.domain.exception.DomainValidationException;

import java.util.Objects;

/**
 * Avis d'un client sur un café. Fait partie de l'agrégat {@link Coffee}.
 */
public record Review(ReviewId id, String author, String comment, int rating) {

    public static final int MIN_RATING = 1;
    public static final int MAX_RATING = 5;

    public Review {
        Objects.requireNonNull(id, "id must not be null");
        Objects.requireNonNull(comment, "comment must not be null");
        if (author == null || author.isBlank()) {
            throw new DomainValidationException("Review author must not be blank");
        }
        if (rating < MIN_RATING || rating > MAX_RATING) {
            throw new DomainValidationException(
                    "Rating must be between %d and %d, got %d".formatted(MIN_RATING, MAX_RATING, rating));
        }
    }
}
EOF

cat > $B/domain/model/Coffee.java <<'EOF'
package org.formation.coffee.domain.model;

import org.formation.coffee.domain.exception.DomainValidationException;
import org.jspecify.annotations.Nullable;

import java.util.List;
import java.util.Objects;

/**
 * Racine d'agrégat du catalogue. Ses avis sont toujours chargés avec elle.
 */
public final class Coffee {

    public static final int MAX_NAME_LENGTH = 255;

    private final @Nullable CoffeeId id;
    private String name;
    private Price price;
    private final List<Review> reviews;

    private Coffee(@Nullable CoffeeId id, String name, Price price, List<Review> reviews) {
        this.id = id;
        this.name = requireValidName(name);
        this.price = Objects.requireNonNull(price, "price must not be null");
        this.reviews = List.copyOf(reviews);
    }

    /**
     * Crée un café pas encore enregistré, donc sans identité.
     */
    public static Coffee create(String name, Price price) {
        return new Coffee(null, name, price, List.of());
    }

    /**
     * Reconstruit un café qui existe déjà dans le stockage.
     */
    public static Coffee reconstitute(CoffeeId id, String name, Price price, List<Review> reviews) {
        return new Coffee(Objects.requireNonNull(id, "id must not be null"), name, price, reviews);
    }

    public void rename(String newName) {
        this.name = requireValidName(newName);
    }

    public void changePrice(Price newPrice) {
        this.price = Objects.requireNonNull(newPrice, "price must not be null");
    }

    public boolean isNew() {
        return id == null;
    }

    public @Nullable CoffeeId getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public Price getPrice() {
        return price;
    }

    public List<Review> getReviews() {
        return reviews;
    }

    private static String requireValidName(@Nullable String name) {
        if (name == null || name.isBlank()) {
            throw new DomainValidationException("Coffee name must not be blank");
        }
        if (name.length() > MAX_NAME_LENGTH) {
            throw new DomainValidationException(
                    "Coffee name must not exceed %d characters".formatted(MAX_NAME_LENGTH));
        }
        return name;
    }

    @Override
    public boolean equals(@Nullable Object other) {
        if (this == other) {
            return true;
        }
        return other instanceof Coffee coffee && id != null && id.equals(coffee.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : System.identityHashCode(this);
    }

    @Override
    public String toString() {
        return "Coffee[id=" + id + ", name=" + name + ", price=" + price + "]";
    }
}
EOF

############################ APPLICATION : ports entrants ############################
cat > $B/application/port/in/ListCoffeesQuery.java <<'EOF'
package org.formation.coffee.application.port.in;

import org.formation.coffee.domain.model.Coffee;

import java.util.List;

public interface ListCoffeesQuery {

    List<Coffee> listCoffees();
}
EOF

cat > $B/application/port/in/GetCoffeeQuery.java <<'EOF'
package org.formation.coffee.application.port.in;

import org.formation.coffee.domain.exception.CoffeeNotFoundException;
import org.formation.coffee.domain.model.Coffee;
import org.formation.coffee.domain.model.CoffeeId;

public interface GetCoffeeQuery {

    /**
     * @throws CoffeeNotFoundException si aucun café n'a cet identifiant
     */
    Coffee getCoffee(CoffeeId id);
}
EOF

cat > $B/application/port/in/CreateCoffeeUseCase.java <<'EOF'
package org.formation.coffee.application.port.in;

import org.formation.coffee.domain.model.Coffee;

public interface CreateCoffeeUseCase {

    Coffee createCoffee(CreateCoffeeCommand command);
}
EOF

cat > $B/application/port/in/UpdateCoffeeUseCase.java <<'EOF'
package org.formation.coffee.application.port.in;

import org.formation.coffee.domain.exception.CoffeeNotFoundException;
import org.formation.coffee.domain.model.Coffee;

public interface UpdateCoffeeUseCase {

    /**
     * @throws CoffeeNotFoundException si aucun café n'a l'identifiant de la commande
     */
    Coffee updateCoffee(UpdateCoffeeCommand command);
}
EOF

cat > $B/application/port/in/CreateCoffeeCommand.java <<'EOF'
package org.formation.coffee.application.port.in;

import org.formation.coffee.domain.model.Price;

import java.util.Objects;

public record CreateCoffeeCommand(String name, Price price) {

    public CreateCoffeeCommand {
        Objects.requireNonNull(name, "name must not be null");
        Objects.requireNonNull(price, "price must not be null");
    }
}
EOF

cat > $B/application/port/in/UpdateCoffeeCommand.java <<'EOF'
package org.formation.coffee.application.port.in;

import org.formation.coffee.domain.model.CoffeeId;
import org.formation.coffee.domain.model.Price;
import org.jspecify.annotations.Nullable;

import java.util.Objects;

/**
 * Mise à jour partielle d'un café : un champ {@code null} reste inchangé.
 */
public record UpdateCoffeeCommand(CoffeeId id, @Nullable String name, @Nullable Price price) {

    public UpdateCoffeeCommand {
        Objects.requireNonNull(id, "id must not be null");
    }
}
EOF

############################ APPLICATION : ports sortants ############################
cat > $B/application/port/out/LoadCoffeePort.java <<'EOF'
package org.formation.coffee.application.port.out;

import org.formation.coffee.domain.model.Coffee;
import org.formation.coffee.domain.model.CoffeeId;

import java.util.List;
import java.util.Optional;

/**
 * Charge des agrégats {@link Coffee} complets, avis compris.
 */
public interface LoadCoffeePort {

    List<Coffee> findAll();

    Optional<Coffee> findById(CoffeeId id);
}
EOF

cat > $B/application/port/out/SaveCoffeePort.java <<'EOF'
package org.formation.coffee.application.port.out;

import org.formation.coffee.domain.model.Coffee;

public interface SaveCoffeePort {

    /**
     * Enregistre un café nouveau ou existant et le renvoie tel qu'enregistré, avec son identité.
     */
    Coffee save(Coffee coffee);
}
EOF

cat > $B/application/port/out/TransactionRunner.java <<'EOF'
package org.formation.coffee.application.port.out;

import java.util.function.Supplier;

/**
 * Exécute une unité de travail dans une transaction, sans annotation de framework dans la couche application.
 */
public interface TransactionRunner {

    <T> T execute(Supplier<T> work);

    <T> T executeReadOnly(Supplier<T> work);
}
EOF

############################ APPLICATION : service ############################
cat > $B/application/service/CoffeeApplicationService.java <<'EOF'
package org.formation.coffee.application.service;

import org.formation.coffee.application.port.in.CreateCoffeeCommand;
import org.formation.coffee.application.port.in.CreateCoffeeUseCase;
import org.formation.coffee.application.port.in.GetCoffeeQuery;
import org.formation.coffee.application.port.in.ListCoffeesQuery;
import org.formation.coffee.application.port.in.UpdateCoffeeCommand;
import org.formation.coffee.application.port.in.UpdateCoffeeUseCase;
import org.formation.coffee.application.port.out.LoadCoffeePort;
import org.formation.coffee.application.port.out.SaveCoffeePort;
import org.formation.coffee.application.port.out.TransactionRunner;
import org.formation.coffee.domain.exception.CoffeeNotFoundException;
import org.formation.coffee.domain.model.Coffee;
import org.formation.coffee.domain.model.CoffeeId;
import org.formation.coffee.domain.model.Price;

import java.util.List;

/**
 * Implémente les cas d'usage des cafés. Java pur : câblé par {@code UseCaseConfig}, sans annotation Spring.
 */
public class CoffeeApplicationService
        implements ListCoffeesQuery, GetCoffeeQuery, CreateCoffeeUseCase, UpdateCoffeeUseCase {

    private final LoadCoffeePort loadCoffeePort;
    private final SaveCoffeePort saveCoffeePort;
    private final TransactionRunner transactionRunner;

    public CoffeeApplicationService(LoadCoffeePort loadCoffeePort,
                                    SaveCoffeePort saveCoffeePort,
                                    TransactionRunner transactionRunner) {
        this.loadCoffeePort = loadCoffeePort;
        this.saveCoffeePort = saveCoffeePort;
        this.transactionRunner = transactionRunner;
    }

    @Override
    public List<Coffee> listCoffees() {
        return transactionRunner.executeReadOnly(loadCoffeePort::findAll);
    }

    @Override
    public Coffee getCoffee(CoffeeId id) {
        return transactionRunner.executeReadOnly(() -> loadCoffee(id));
    }

    @Override
    public Coffee createCoffee(CreateCoffeeCommand command) {
        return transactionRunner.execute(
                () -> saveCoffeePort.save(Coffee.create(command.name(), command.price())));
    }

    @Override
    public Coffee updateCoffee(UpdateCoffeeCommand command) {
        return transactionRunner.execute(() -> {
            Coffee coffee = loadCoffee(command.id());
            String name = command.name();
            if (name != null) {
                coffee.rename(name);
            }
            Price price = command.price();
            if (price != null) {
                coffee.changePrice(price);
            }
            return saveCoffeePort.save(coffee);
        });
    }

    private Coffee loadCoffee(CoffeeId id) {
        return loadCoffeePort.findById(id).orElseThrow(() -> new CoffeeNotFoundException(id));
    }
}
EOF

############################ ADAPTATEUR SORTANT : persistance ############################
cat > $B/adapter/out/persistence/CoffeeJpaEntity.java <<'EOF'
package org.formation.coffee.adapter.out.persistence;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import org.jspecify.annotations.Nullable;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "coffee")
class CoffeeJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private @Nullable Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private int price;

    @OneToMany(mappedBy = "coffee", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("id")
    private List<ReviewJpaEntity> reviews = new ArrayList<>();

    protected CoffeeJpaEntity() {
        // pour JPA et MapStruct
    }

    public @Nullable Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getPrice() {
        return price;
    }

    public void setPrice(int price) {
        this.price = price;
    }

    public List<ReviewJpaEntity> getReviews() {
        return reviews;
    }
}
EOF

cat > $B/adapter/out/persistence/ReviewJpaEntity.java <<'EOF'
package org.formation.coffee.adapter.out.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import org.jspecify.annotations.Nullable;

@Entity
@Table(name = "review")
class ReviewJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private @Nullable Long id;

    @Column(nullable = false)
    private String author;

    @Column(nullable = false)
    private String comment;

    @Column(nullable = false)
    private int rating;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "coffee_id", nullable = false)
    private CoffeeJpaEntity coffee;

    protected ReviewJpaEntity() {
        // pour JPA
    }

    public @Nullable Long getId() {
        return id;
    }

    public String getAuthor() {
        return author;
    }

    public String getComment() {
        return comment;
    }

    public int getRating() {
        return rating;
    }
}
EOF

cat > $B/adapter/out/persistence/CoffeeJpaRepository.java <<'EOF'
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
EOF

cat > $B/adapter/out/persistence/CoffeePersistenceMapper.java <<'EOF'
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
EOF

cat > $B/adapter/out/persistence/CoffeePersistenceAdapter.java <<'EOF'
package org.formation.coffee.adapter.out.persistence;

import org.formation.coffee.application.port.out.LoadCoffeePort;
import org.formation.coffee.application.port.out.SaveCoffeePort;
import org.formation.coffee.domain.exception.CoffeeNotFoundException;
import org.formation.coffee.domain.model.Coffee;
import org.formation.coffee.domain.model.CoffeeId;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

@Component
class CoffeePersistenceAdapter implements LoadCoffeePort, SaveCoffeePort {

    private final CoffeeJpaRepository repository;
    private final CoffeePersistenceMapper mapper;

    CoffeePersistenceAdapter(CoffeeJpaRepository repository, CoffeePersistenceMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Override
    public List<Coffee> findAll() {
        return repository.findAllByOrderByIdAsc().stream().map(mapper::toDomain).toList();
    }

    @Override
    public Optional<Coffee> findById(CoffeeId id) {
        return repository.findWithReviewsById(id.value()).map(mapper::toDomain);
    }

    @Override
    public Coffee save(Coffee coffee) {
        CoffeeId id = coffee.getId();
        if (id == null) {
            return mapper.toDomain(repository.save(mapper.toNewEntity(coffee)));
        }
        CoffeeJpaEntity managed = repository.findWithReviewsById(id.value())
                .orElseThrow(() -> new CoffeeNotFoundException(id));
        mapper.updateEntity(coffee, managed);
        return mapper.toDomain(managed);
    }
}
EOF

############################ ADAPTATEUR SORTANT : transactions ############################
cat > $B/adapter/out/transaction/SpringTransactionRunner.java <<'EOF'
package org.formation.coffee.adapter.out.transaction;

import org.formation.coffee.application.port.out.TransactionRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.function.Supplier;

@Component
class SpringTransactionRunner implements TransactionRunner {

    private final TransactionTemplate readWrite;
    private final TransactionTemplate readOnly;

    SpringTransactionRunner(PlatformTransactionManager transactionManager) {
        this.readWrite = new TransactionTemplate(transactionManager);
        this.readOnly = new TransactionTemplate(transactionManager);
        this.readOnly.setReadOnly(true);
    }

    @Override
    public <T> T execute(Supplier<T> work) {
        return readWrite.execute(status -> work.get());
    }

    @Override
    public <T> T executeReadOnly(Supplier<T> work) {
        return readOnly.execute(status -> work.get());
    }
}
EOF

############################ ADAPTATEUR ENTRANT : DTO ############################
cat > $B/adapter/in/web/dto/CreateCoffeeRequest.java <<'EOF'
package org.formation.coffee.adapter.in.web.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Seule la forme de la requête est validée ici ; les règles métier (plage de prix, longueur du nom)
 * appartiennent au domaine.
 */
public record CreateCoffeeRequest(@NotBlank String name, @NotNull Integer price) {
}
EOF

cat > $B/adapter/in/web/dto/UpdateCoffeeRequest.java <<'EOF'
package org.formation.coffee.adapter.in.web.dto;

import org.jspecify.annotations.Nullable;

/**
 * Mise à jour partielle : un champ absent reste inchangé.
 */
public record UpdateCoffeeRequest(@Nullable String name, @Nullable Integer price) {
}
EOF

cat > $B/adapter/in/web/dto/CoffeeResponse.java <<'EOF'
package org.formation.coffee.adapter.in.web.dto;

import java.util.List;

public record CoffeeResponse(long id, String name, int price, List<ReviewResponse> reviews) {
}
EOF

cat > $B/adapter/in/web/dto/ReviewResponse.java <<'EOF'
package org.formation.coffee.adapter.in.web.dto;

public record ReviewResponse(long id, String author, String comment, int rating) {
}
EOF

############################ ADAPTATEUR ENTRANT : web ############################
cat > $B/adapter/in/web/CoffeeWebMapper.java <<'EOF'
package org.formation.coffee.adapter.in.web;

import org.formation.coffee.adapter.in.web.dto.CoffeeResponse;
import org.formation.coffee.adapter.in.web.dto.CreateCoffeeRequest;
import org.formation.coffee.adapter.in.web.dto.ReviewResponse;
import org.formation.coffee.adapter.in.web.dto.UpdateCoffeeRequest;
import org.formation.coffee.application.port.in.CreateCoffeeCommand;
import org.formation.coffee.application.port.in.UpdateCoffeeCommand;
import org.formation.coffee.domain.model.Coffee;
import org.formation.coffee.domain.model.CoffeeId;
import org.formation.coffee.domain.model.Price;
import org.formation.coffee.domain.model.Review;
import org.formation.coffee.domain.model.ReviewId;
import org.jspecify.annotations.Nullable;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper
interface CoffeeWebMapper {

    CoffeeResponse toResponse(Coffee coffee);

    ReviewResponse toReviewResponse(Review review);

    CreateCoffeeCommand toCommand(CreateCoffeeRequest request);

    @Mapping(target = "id", source = "id")
    @Mapping(target = "name", source = "request.name")
    @Mapping(target = "price", source = "request.price")
    UpdateCoffeeCommand toCommand(long id, UpdateCoffeeRequest request);

    default long toValue(CoffeeId id) {
        return id.value();
    }

    default long toValue(ReviewId id) {
        return id.value();
    }

    default int toAmount(Price price) {
        return price.amount();
    }

    default CoffeeId toCoffeeId(long id) {
        return new CoffeeId(id);
    }

    default @Nullable Price toPrice(@Nullable Integer amount) {
        return amount == null ? null : new Price(amount);
    }
}
EOF

cat > $B/adapter/in/web/CoffeeController.java <<'EOF'
package org.formation.coffee.adapter.in.web;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.formation.coffee.adapter.in.web.dto.CoffeeResponse;
import org.formation.coffee.adapter.in.web.dto.CreateCoffeeRequest;
import org.formation.coffee.adapter.in.web.dto.UpdateCoffeeRequest;
import org.formation.coffee.application.port.in.CreateCoffeeUseCase;
import org.formation.coffee.application.port.in.GetCoffeeQuery;
import org.formation.coffee.application.port.in.ListCoffeesQuery;
import org.formation.coffee.application.port.in.UpdateCoffeeUseCase;
import org.formation.coffee.domain.model.Coffee;
import org.formation.coffee.domain.model.CoffeeId;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping(path = "/api/coffees", version = "1")
@Tag(name = "Coffees", description = "Coffee catalog")
class CoffeeController {

    private final ListCoffeesQuery listCoffeesQuery;
    private final GetCoffeeQuery getCoffeeQuery;
    private final CreateCoffeeUseCase createCoffeeUseCase;
    private final UpdateCoffeeUseCase updateCoffeeUseCase;
    private final CoffeeWebMapper mapper;

    CoffeeController(ListCoffeesQuery listCoffeesQuery,
                     GetCoffeeQuery getCoffeeQuery,
                     CreateCoffeeUseCase createCoffeeUseCase,
                     UpdateCoffeeUseCase updateCoffeeUseCase,
                     CoffeeWebMapper mapper) {
        this.listCoffeesQuery = listCoffeesQuery;
        this.getCoffeeQuery = getCoffeeQuery;
        this.createCoffeeUseCase = createCoffeeUseCase;
        this.updateCoffeeUseCase = updateCoffeeUseCase;
        this.mapper = mapper;
    }

    @GetMapping
    @Operation(summary = "List all coffees with their reviews")
    List<CoffeeResponse> listCoffees() {
        return listCoffeesQuery.listCoffees().stream().map(mapper::toResponse).toList();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a coffee by its id")
    CoffeeResponse getCoffee(@PathVariable long id) {
        return mapper.toResponse(getCoffeeQuery.getCoffee(new CoffeeId(id)));
    }

    @PostMapping
    @Operation(summary = "Create a coffee")
    ResponseEntity<CoffeeResponse> createCoffee(@Valid @RequestBody CreateCoffeeRequest request,
                                                UriComponentsBuilder uriBuilder) {
        Coffee created = createCoffeeUseCase.createCoffee(mapper.toCommand(request));
        CoffeeResponse response = mapper.toResponse(created);
        URI location = uriBuilder.path("/api/coffees/{id}").buildAndExpand(response.id()).toUri();
        return ResponseEntity.created(location).body(response);
    }

    @PatchMapping("/{id}")
    @Operation(summary = "Partially update a coffee")
    CoffeeResponse updateCoffee(@PathVariable long id, @Valid @RequestBody UpdateCoffeeRequest request) {
        return mapper.toResponse(updateCoffeeUseCase.updateCoffee(mapper.toCommand(id, request)));
    }
}
EOF

cat > $B/adapter/in/web/RestExceptionHandler.java <<'EOF'
package org.formation.coffee.adapter.in.web;

import org.formation.coffee.domain.exception.CoffeeNotFoundException;
import org.formation.coffee.domain.exception.DomainValidationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Traduit les exceptions du domaine en problem details RFC 9457.
 * Les exceptions du framework (validation, JSON invalide) sont déjà gérées par Spring Boot.
 */
@RestControllerAdvice
class RestExceptionHandler {

    @ExceptionHandler
    ProblemDetail handleNotFound(CoffeeNotFoundException exception) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, exception.getMessage());
        problem.setTitle("Coffee not found");
        problem.setProperty("coffeeId", exception.getCoffeeId().value());
        return problem;
    }

    @ExceptionHandler
    ProblemDetail handleValidation(DomainValidationException exception) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.UNPROCESSABLE_CONTENT, exception.getMessage());
        problem.setTitle("Business rule violated");
        return problem;
    }
}
EOF

############################ CONFIG ############################
cat > $B/config/UseCaseConfig.java <<'EOF'
package org.formation.coffee.config;

import org.formation.coffee.application.port.out.LoadCoffeePort;
import org.formation.coffee.application.port.out.SaveCoffeePort;
import org.formation.coffee.application.port.out.TransactionRunner;
import org.formation.coffee.application.service.CoffeeApplicationService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Branche les services applicatifs, écrits sans framework, dans le contexte Spring.
 */
@Configuration(proxyBeanMethods = false)
class UseCaseConfig {

    @Bean
    CoffeeApplicationService coffeeApplicationService(LoadCoffeePort loadCoffeePort,
                                                      SaveCoffeePort saveCoffeePort,
                                                      TransactionRunner transactionRunner) {
        return new CoffeeApplicationService(loadCoffeePort, saveCoffeePort, transactionRunner);
    }
}
EOF

echo "OK : $(find $B -name '*.java' ! -name package-info.java | wc -l) classes Java créées."
