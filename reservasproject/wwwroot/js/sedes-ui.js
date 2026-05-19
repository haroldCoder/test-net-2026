function clearAvailabilitySearch() {
    isSearchingAvailability = false;
    availableUnits = [];

    // Ocultar botón de limpiar
    document.getElementById("clearDatesBtn").classList.add("d-none");

    // Resetear formulario
    const today = new Date().toISOString().split('T')[0];
    const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];
    document.getElementById("checkInDate").value = today;
    document.getElementById("checkOutDate").value = tomorrow;
    document.getElementById("guestCount").value = "";
    document.getElementById("searchInput").value = "";

    renderPlaces();
}

function filterPlaces(type, btn) {
    document.querySelectorAll(".filter-btn").forEach(b => b.classList.remove("active"));
    btn.classList.add("active");

    activeType = type;
    renderPlaces();
}

function renderPlaces() {
    const grid = document.getElementById("placesGrid");
    const searchVal = document.getElementById("searchInput").value.toLowerCase();

    grid.innerHTML = "";

    // Filtrar sedes base por categoría y búsqueda de texto
    const filteredSedes = allPlaces.filter(place => {
        const matchesType = activeType === 'todos' || place.tipo === activeType;
        const matchesSearch = place.nombre.toLowerCase().includes(searchVal) ||
            place.ciudad.toLowerCase().includes(searchVal);
        return matchesType && matchesSearch;
    });

    if (filteredSedes.length === 0) {
        grid.innerHTML = `
            <div class="no-results">
                <i class="bi bi-search"></i>
                <h4>No encontramos resultados</h4>
                <p>Intenta buscando con palabras clave diferentes o cambia de categoría.</p>
            </div>
        `;
        return;
    }

    filteredSedes.forEach((place, index) => {
        const badgeClass = place.tipo === 'Apartamento' ? 'badge-apartamento' : 'badge-sede';
        const gradientIndex = index % backgroundGradients.length;
        const cardBg = backgroundGradients[gradientIndex];

        let availabilityBadge = '';
        let cardClass = 'place-card';
        let actionBtnText = 'Ver Detalles';
        let onClickAction = `showSedeDetails(${place.id}, '${place.nombre}', '${place.tipo}')`;
        let isBtnDisabled = '';

        if (isSearchingAvailability) {
            // Filtrar unidades disponibles de esta Sede
            const unitsForSede = availableUnits.filter(u => u.sedeNombre === place.nombre);
            const count = unitsForSede.length;

            if (count > 0) {
                availabilityBadge = `<span class="status-badge status-available">🟢 ${count} Libres</span>`;
                actionBtnText = 'Ver Opciones <i class="bi bi-arrow-right"></i>';
            } else {
                availabilityBadge = `<span class="status-badge status-unavailable">🔴 Agotado</span>`;
                cardClass += ' unavailable';
                actionBtnText = 'Sin Lugares';
                isBtnDisabled = 'disabled';
                onClickAction = '';
            }
        }

        const cardHtml = `
            <div class="${cardClass}" style="animation-delay: ${index * 0.08}s">
                <div class="place-card-image" style="background: ${cardBg}">
                    ${availabilityBadge}
                    <span class="place-badge ${badgeClass}">${place.tipo}</span>
                </div>
                <div class="place-body">
                    <div>
                        <h3 class="place-title">${place.nombre}</h3>
                        <div class="place-city">
                            <i class="bi bi-geo-alt"></i> ${place.ciudad}
                        </div>
                    </div>
                    <div class="place-footer">
                        <span class="text-muted font-sm">
                            <i class="bi bi-shield-check text-success"></i> Verificado
                        </span>
                        <button class="place-action-btn" ${isBtnDisabled} onclick="${onClickAction}">
                            ${actionBtnText}
                        </button>
                    </div>
                </div>
            </div>
        `;
        grid.insertAdjacentHTML('beforeend', cardHtml);
    });
}

// Modal de detalles de unidades de alojamiento
function showSedeDetails(sedeId, sedeNombre, SedeTipo) {
    const modalTitle = document.getElementById("sedeDetailsModalLabel");
    const modalBody = document.getElementById("sedeDetailsModalBody");

    modalTitle.innerHTML = `<i class="bi bi-building-fill-check"></i> ${sedeNombre}`;
    modalBody.innerHTML = "";

    if (!isSearchingAvailability) {
        // Si no ha buscado por fechas
        modalBody.innerHTML = `
            <div class="text-center py-4">
                <i class="bi bi-calendar-range text-primary" style="font-size: 3rem;"></i>
                <h5 class="mt-3 font-weight-bold">Consulta de Disponibilidad</h5>
                <p class="text-muted px-4">Para ver las habitaciones, cabañas y tarifas libres en <strong>${sedeNombre}</strong>, por favor selecciona tus fechas de viaje en el panel superior y presiona buscar.</p>
                <button class="btn btn-primary rounded-pill px-4 mt-2" data-bs-dismiss="modal" onclick="document.getElementById('checkInDate').focus()">
                    Seleccionar Fechas
                </button>
            </div>
        `;
    } else {
        // Filtrar unidades disponibles asociadas a esta Sede
        const units = availableUnits.filter(u => u.sedeNombre === sedeNombre);

        if (units.length === 0) {
            modalBody.innerHTML = `
                <div class="text-center py-4">
                    <i class="bi bi-emoji-frown text-warning" style="font-size: 3rem;"></i>
                    <h5 class="mt-3 font-weight-bold">No hay unidades disponibles</h5>
                    <p class="text-muted px-4">Lo sentimos, no hay cabañas ni apartamentos disponibles para el rango de fechas seleccionado.</p>
                </div>
            `;
        } else {
            const checkIn = document.getElementById("checkInDate").value;
            const checkOut = document.getElementById("checkOutDate").value;
            const nights = Math.max(1, Math.round((new Date(checkOut) - new Date(checkIn)) / 86400000));

            let modalHtml = '';

            // 1. Mostrar servicios opcionales adicionales al inicio si aplica
            modalHtml += buildAddonsHtml(SedeTipo, sedeId, sedeNombre);

            modalHtml += '<div class="unit-list">';
            units.forEach(unit => {
                modalHtml += buildUnitCardHtml(unit, sedeNombre, nights);
            });

            modalHtml += '</div>';
            modalBody.innerHTML = modalHtml;
        }
    }

    // Mostrar el modal
    const detailsModal = new bootstrap.Modal(document.getElementById('sedeDetailsModal'));
    detailsModal.show();
}

// Helpers HTML
function buildAddonsHtml(SedeTipo, sedeId, sedeNombre) {
    if (SedeTipo === 'Sede Recreativa') {
        return `
            <div class="addons-card-wrapper mb-4">
                <h6 class="addon-row-title"><i class="bi bi-gift"></i> Servicios Opcionales para Sedes Recreativas</h6>
                <div class="row align-items-center">
                    <div class="col-md-8">
                        <label class="addon-label">Acompañantes Adicionales por Día (Pasadía)</label>
                        <p class="addon-description">Permite registrar acompañantes adicionales. Cada persona a partir de la 5ª y hasta la 10ª paga $5.500 COP por noche de estadía.</p>
                    </div>
                    <div class="col-md-4 text-md-end">
                        <div class="input-group input-group-sm justify-content-md-end" style="max-width: 140px; margin-left: auto;">
                            <button class="btn btn-outline-secondary" type="button" onclick="decrementAddon('acompanantesAddonInput')">-</button>
                            <input type="text" id="acompanantesAddonInput" class="form-control text-center fw-bold" value="0" readonly onchange="recalculateAll(${sedeId}, '${SedeTipo}', '${sedeNombre}')" />
                            <button class="btn btn-outline-secondary" type="button" onclick="incrementAddon('acompanantesAddonInput', 15)">+</button>
                        </div>
                    </div>
                </div>
            </div>
        `;
    } else if (SedeTipo === 'Apartamento' && sedeNombre.includes('Santa Marta')) {
        return `
            <div class="addons-card-wrapper mb-4">
                <h6 class="addon-row-title"><i class="bi bi-gift"></i> Servicios Opcionales para Apartamentos</h6>
                <div class="row align-items-center">
                    <div class="col-md-9">
                        <label class="addon-label">Servicio de Lavandería completo</label>
                        <p class="addon-description">¿Deseas incluir servicio de lavandería por toda la estadía? Aplica un cargo único total de $18.000 COP.</p>
                    </div>
                    <div class="col-md-3 text-md-end">
                        <div class="form-check form-switch d-inline-block">
                            <input class="form-check-input" type="checkbox" role="switch" id="lavanderiaAddonCheck" style="transform: scale(1.4); cursor: pointer;" onchange="recalculateAll(${sedeId}, '${SedeTipo}', '${sedeNombre}')" />
                        </div>
                    </div>
                </div>
            </div>
        `;
    }
    return '';
}

function buildUnitCardHtml(unit, sedeNombre, nights) {
    const icon = unit.tipoAlojamiento.toLowerCase().includes('cabaña') ? 'bi-house-heart' : 'bi-door-closed';
    const bedDetailsHtml = unit.detalleCamas ? `
        <div class="mt-2 text-muted small">
            <i class="bi bi-info-circle text-primary"></i> ${unit.detalleCamas}
        </div>` : '';

    return `
        <div class="card border-0 shadow-sm rounded-4 mb-3" style="background: white; border: 1.5px solid #e2e8f0 !important;">
            <div class="p-3">
                <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3">
                    <div class="unit-info-header">
                        <div class="unit-icon-wrapper">
                            <i class="bi ${icon}"></i>
                        </div>
                        <div>
                            <h4 class="unit-title">${unit.unidadNombre}</h4>
                            <div class="unit-details">
                                <span><i class="bi bi-house"></i> ${unit.tipoAlojamiento}</span>
                                <span><i class="bi bi-people"></i> Máx: ${unit.capacidadMaxima}</span>
                                <span><i class="bi bi-door-open"></i> Alcobas: ${unit.habitacionesInternas}</span>
                            </div>
                            ${bedDetailsHtml}
                        </div>
                    </div>
                    <div class="unit-pricing-wrapper">
                        <span id="price-display-${unit.unidadId}" class="unit-price-display">
                            $${unit.tarifaTotalInicial.toLocaleString('es-CO')} COP
                        </span>
                        <span class="unit-price-subtext">Estadía Total (${nights} ${nights === 1 ? 'noche' : 'noches'})</span>
                    </div>
                </div>

                <div class="tariff-breakdown-wrapper mt-3" id="breakdown-wrapper-${unit.unidadId}">
                    <h6 class="tariff-breakdown-title"><i class="bi bi-receipt"></i> Detalle de la Tarifa</h6>
                    <table class="table tariff-table">
                        <tbody>
                            <tr>
                                <td class="label-column"><i class="bi bi-building"></i> Hospedaje Base (${nights} ${nights === 1 ? 'noche' : 'noches'})</td>
                                <td class="val-column" id="val-base-${unit.unidadId}">$${unit.tarifaTotalInicial.toLocaleString('es-CO')}</td>
                            </tr>
                            <tr class="addon-field-row d-none" id="row-acompanantes-${unit.unidadId}">
                                <td class="label-column"><i class="bi bi-people"></i> Acompañantes Pasadía</td>
                                <td class="val-column" id="val-acompanantes-${unit.unidadId}">$0</td>
                            </tr>
                            <tr class="addon-field-row d-none" id="row-lavanderia-${unit.unidadId}">
                                <td class="label-column"><i class="bi bi-water"></i> Servicio de Lavandería</td>
                                <td class="val-column" id="val-lavanderia-${unit.unidadId}">$0</td>
                            </tr>
                            <tr class="total-row">
                                <td class="label-column"><i class="bi bi-credit-card-fill"></i> TOTAL A PAGAR</td>
                                <td class="val-column" id="val-total-${unit.unidadId}">$${unit.tarifaTotalInicial.toLocaleString('es-CO')}</td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <div class="mt-3 text-end pt-2 border-top border-light">
                    <button class="btn-book-unit px-4 py-2" onclick="bookUnit(${unit.unidadId}, '${unit.unidadNombre}', '${sedeNombre}')">
                        Reservar Unidad
                    </button>
                </div>
            </div>
        </div>
    `;
}

// Helpers para incrementar/decrementar num de acompañantes
function incrementAddon(inputId, max) {
    const input = document.getElementById(inputId);
    let val = parseInt(input.value) || 0;
    if (val < max) {
        input.value = val + 1;
        input.dispatchEvent(new Event('change'));
    }
}

function decrementAddon(inputId) {
    const input = document.getElementById(inputId);
    let val = parseInt(input.value) || 0;
    if (val > 0) {
        input.value = val - 1;
        input.dispatchEvent(new Event('change'));
    }
}
