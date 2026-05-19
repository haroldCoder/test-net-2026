async function fetchPlaces() {
    try {
        const response = await fetch('/Sedes/GetSedes');
        if (!response.ok) throw new Error("Error en la respuesta del servidor");

        allPlaces = await response.json();
        renderPlaces();
    } catch (error) {
        console.error("Error al cargar las sedes:", error);
        document.getElementById("placesGrid").innerHTML = `
            <div class="no-results text-danger">
                <i class="bi bi-exclamation-triangle-fill text-danger"></i>
                <h4>Error al cargar los datos</h4>
                <p>No se pudo conectar al servidor. Inténtalo de nuevo más tarde.</p>
            </div>
        `;
    }
}

// Búsqueda de disponibilidad por fechas
async function searchAvailability(event) {
    event.preventDefault();

    const checkIn = document.getElementById("checkInDate").value;
    const checkOut = document.getElementById("checkOutDate").value;
    const guests = document.getElementById("guestCount").value;

    const spinner = document.getElementById("loadingSpinner");
    const grid = document.getElementById("placesGrid");

    if (!checkIn || !checkOut) {
        alert("Por favor selecciona las fechas de entrada y salida.");
        return;
    }

    grid.innerHTML = "";
    if (spinner) spinner.style.display = "block";

    try {
        let url = `/Sedes/GetAvailableSedes?startDate=${checkIn}&endDate=${checkOut}`;
        if (guests) {
            url += `&guests=${guests}`;
        }

        const response = await fetch(url);
        if (!response.ok) throw new Error("Error en la búsqueda de disponibilidad");

        availableUnits = await response.json();
        isSearchingAvailability = true;

        // Mostrar botón de limpiar fechas
        document.getElementById("clearDatesBtn").classList.remove("d-none");

        renderPlaces();
    } catch (error) {
        console.error("Error en disponibilidad:", error);
        alert("Hubo un problema al consultar la disponibilidad. Inténtalo de nuevo.");
        isSearchingAvailability = false;
        fetchPlaces();
    }
}

// Recalcular tarifas en base a los servicios opcionales elegidos
async function recalculateAll(sedeId, SedeTipo, sedeNombre) {
    const checkIn = document.getElementById("checkInDate").value;
    const checkOut = document.getElementById("checkOutDate").value;
    const guestsInput = document.getElementById("guestCount").value;
    const guests = guestsInput ? parseInt(guestsInput) : 1;

    // Obtener los valores de los inputs adicionales si existen en la UI
    const acompanantesInput = document.getElementById("acompanantesAddonInput");
    const acompanantes = acompanantesInput ? parseInt(acompanantesInput.value) : 0;

    const lavanderiaCheck = document.getElementById("lavanderiaAddonCheck");
    const lavanderia = lavanderiaCheck ? lavanderiaCheck.checked : false;

    // Filtrar las unidades mostradas en la pantalla
    const units = availableUnits.filter(u => u.sedeNombre === sedeNombre);

    for (let unit of units) {
        try {
            // Consulta de recálculo dinámica al endpoint
            const url = `/Sedes/GetCalculatedTariff?unitId=${unit.unidadId}&startDate=${checkIn}&endDate=${checkOut}&guests=${guests}&companions=${acompanantes}&laundry=${lavanderia}`;
            const response = await fetch(url);

            if (!response.ok) throw new Error("Error en cálculo");

            const pricing = await response.json();

            // Actualizar el DOM de forma reactiva y con transiciones
            const priceDisplay = document.getElementById(`price-display-${unit.unidadId}`);
            if (priceDisplay) {
                priceDisplay.innerHTML = `$${pricing.totalAPagar.toLocaleString('es-CO')} COP`;
            }

            // Actualizar Desglose
            const valBase = document.getElementById(`val-base-${unit.unidadId}`);
            if (valBase) valBase.innerHTML = `$${pricing.subtotalHospedaje.toLocaleString('es-CO')}`;

            const rowAcompanantes = document.getElementById(`row-acompanantes-${unit.unidadId}`);
            const valAcompanantes = document.getElementById(`val-acompanantes-${unit.unidadId}`);
            if (pricing.totalAcompanantesDia > 0) {
                if (rowAcompanantes) rowAcompanantes.classList.remove("d-none");
                if (valAcompanantes) valAcompanantes.innerHTML = `$${pricing.totalAcompanantesDia.toLocaleString('es-CO')}`;
            } else {
                if (rowAcompanantes) rowAcompanantes.classList.add("d-none");
            }

            const rowLavanderia = document.getElementById(`row-lavanderia-${unit.unidadId}`);
            const valLavanderia = document.getElementById(`val-lavanderia-${unit.unidadId}`);
            if (pricing.servicioLavanderia > 0) {
                if (rowLavanderia) rowLavanderia.classList.remove("d-none");
                if (valLavanderia) valLavanderia.innerHTML = `$${pricing.servicioLavanderia.toLocaleString('es-CO')}`;
            } else {
                if (rowLavanderia) rowLavanderia.classList.add("d-none");
            }

            const valTotal = document.getElementById(`val-total-${unit.unidadId}`);
            if (valTotal) valTotal.innerHTML = `$${pricing.totalAPagar.toLocaleString('es-CO')}`;

        } catch (error) {
            console.error("Error al calcular precio dinámico:", error);
        }
    }
}
