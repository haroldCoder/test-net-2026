const renderPlaces = () => {
    const grid = document.getElementById("placesGrid");
    
    if (!allPlaces || allPlaces.length === 0) {
        grid.innerHTML = `
            <div class="col-12">
                <div class="card border-0 shadow-sm rounded-4 text-center py-5 mt-4" style="background: rgba(255,255,255,0.8); backdrop-filter: blur(10px);">
                    <div class="card-body py-5">
                        <i class="bi bi-calendar-x text-muted" style="font-size: 4rem;"></i>
                        <h3 class="mt-4 fw-bold">Aún no tienes reservas</h3>
                        <p class="text-muted mb-4 px-3">Parece que todavía no has programado ningún viaje con nosotros. ¡Explora nuestros destinos y anímate a reservar tu primer descanso!</p>
                        <a href="/Sedes" class="btn btn-outline-primary rounded-pill px-4">Explorar Destinos</a>
                    </div>
                </div>
            </div>
        `;
        return;
    }

    let html = '';
    
    allPlaces.forEach(booking => {
        let statusColor = "bg-secondary text-white";
        let statusIcon = '<i class="bi bi-check-circle me-1"></i>';
        
        if (booking.status === "Próxima") {
            statusColor = "bg-success text-white";
            statusIcon = '<i class="bi bi-calendar-event me-1"></i>';
        } else if (booking.status === "En Curso") {
            statusColor = "bg-primary text-white";
            statusIcon = '<i class="bi bi-play-circle me-1"></i>';
        }

        const cardOpacity = booking.status === "Finalizada" ? "opacity-75" : "opacity-100";
        
        // Formatear fechas como "dd MMM yyyy"
        const formatDate = (dateString) => {
            const options = { day: '2-digit', month: 'short', year: 'numeric' };
            const d = new Date(dateString);
            return d.toLocaleDateString('es-ES', options).replace('.', '');
        };
        
        const startDateFmt = formatDate(booking.startDate);
        const endDateFmt = formatDate(booking.endDate);
        
        // Servicios
        let servicesHtml = '';
        if (booking.usaLavanderia || booking.acompanantesDia > 0) {
            servicesHtml += '<div class="d-flex flex-wrap gap-2 mb-3">';
            if (booking.usaLavanderia) {
                servicesHtml += `
                    <span class="badge rounded-pill bg-info text-dark px-3 py-2 fw-normal" style="font-size: 0.8rem;">
                        <i class="bi bi-droplet-fill me-1"></i> Lavandería incluida
                    </span>`;
            }
            if (booking.acompanantesDia > 0) {
                const s = booking.acompanantesDia !== 1 ? 's' : '';
                servicesHtml += `
                    <span class="badge rounded-pill bg-warning text-dark px-3 py-2 fw-normal" style="font-size: 0.8rem;">
                        <i class="bi bi-people-fill me-1"></i> ${booking.acompanantesDia} acompañante${s} (pasadía)
                    </span>`;
            }
            servicesHtml += '</div>';
        }
        
        const totalPeople = booking.guests + booking.acompanantesDia;
        const peopleS = totalPeople !== 1 ? 's' : '';
        
        let acompanantesInfoHtml = '';
        if (booking.acompanantesDia > 0) {
            const accS = booking.acompanantesDia !== 1 ? 's' : '';
            acompanantesInfoHtml = `<span class="text-muted small d-block">(${booking.guests} titular + ${booking.acompanantesDia} acompañante${accS})</span>`;
        }

        // ID padded con ceros (ej: #00001)
        const paddedId = booking.bookingId.toString().padStart(5, '0');

        html += `
            <div class="col">
                <div class="card border-0 shadow-sm rounded-4 h-100 ${cardOpacity}" style="transition: transform 0.2s;">
                    <div class="card-header border-0 pb-0 bg-transparent mt-2 d-flex justify-content-between align-items-center">
                        <span class="badge rounded-pill ${statusColor} px-3 py-2 fw-normal" style="font-size: 0.85rem;">
                            ${statusIcon} ${booking.status}
                        </span>
                        <span class="text-muted small fw-bold">ID: #${paddedId}</span>
                    </div>
                    <div class="card-body">
                        <h4 class="card-title fw-bold text-dark mb-1">${booking.unitName}</h4>
                        <p class="text-muted mb-3"><i class="bi bi-geo-alt"></i> ${booking.sedeName}</p>
                        
                        <div class="bg-light rounded-3 p-3 mb-3 border">
                            <div class="row text-center">
                                <div class="col-6 border-end">
                                    <small class="text-muted d-block mb-1">Entrada</small>
                                    <span class="fw-bold text-dark">${startDateFmt}</span>
                                </div>
                                <div class="col-6">
                                    <small class="text-muted d-block mb-1">Salida</small>
                                    <span class="fw-bold text-dark">${endDateFmt}</span>
                                </div>
                            </div>
                        </div>
                        
                        ${servicesHtml}

                        <div class="d-flex justify-content-between align-items-end mt-2">
                            <div>
                                <span class="text-muted small"><i class="bi bi-people"></i> ${totalPeople} persona${peopleS}</span>
                                ${acompanantesInfoHtml}
                            </div>
                            <div class="text-end">
                                <small class="text-muted d-block" style="font-size: 0.75rem;">Total Pagado</small>
                                <span class="fw-bolder fs-5 text-primary">$${booking.totalPaid.toLocaleString('es-ES')}</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
    });

    grid.innerHTML = html;
};