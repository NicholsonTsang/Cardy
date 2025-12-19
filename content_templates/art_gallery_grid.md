# Art Gallery - Grouped Grid Mode (Digital Access)

A contemporary art exhibition showcasing visual works in a 2-column gallery layout, organized by medium. Perfect for museums, galleries, and art exhibitions where visitors want to browse artworks visually.

---

## Card Settings

```yaml
name: "Modern Visions: Contemporary Art Collection"
description: |
  Welcome to **Modern Visions**, featuring 12 groundbreaking contemporary artworks 
  that challenge perception and celebrate human creativity.
  
  This exhibition brings together emerging and established artists exploring themes 
  of identity, technology, and the natural world through painting, sculpture, 
  and mixed media.
  
  🎨 Tap any artwork to learn more and chat with our AI art guide.

content_mode: grid
is_grouped: true
group_display: expanded
billing_type: digital
image_url: "[Upload: Exhibition poster or signature artwork]"

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are an enthusiastic art docent at a contemporary art gallery. 
  Speak with passion about the artworks, artists, and artistic movements. 
  Help visitors understand the meaning, techniques, and context behind each piece. 
  Be approachable and encourage questions. Avoid overly academic language.

ai_knowledge_base: |
  Modern Visions Exhibition - Contemporary Art Collection 2024
  
  Exhibition themes: Identity in the digital age, environmental consciousness, 
  urban life, human connection, abstraction and emotion.
  
  Gallery layout: Main hall (large installations), East wing (paintings), 
  West wing (sculptures and mixed media), North gallery (digital art).
  
  Artist talks every Saturday at 2pm. Guided tours at 11am and 3pm daily.
  Gift shop near exit with exhibition catalog and prints available.
  Photography allowed without flash. No touching artworks.

ai_welcome_general: "Welcome to Modern Visions! I can tell you about any artwork's meaning, the artist's story, techniques used, or suggest what to see based on your interests. What draws your attention?"
ai_welcome_item: "This is \"{name}\" - I can share the artist's inspiration, explain the technique, give historical context, or connect it to other works here. What interests you?"
```

---

## Categories (Layer 1)

### 🖼️ Paintings
Traditional and contemporary painting techniques. Located in the East Wing.

### 🗿 Sculptures
Three-dimensional works in various materials. Located in the West Wing.

### 💻 Digital Art
Technology-driven and generative works. Located in the North Gallery.

### 🏛️ Installations
Large-scale immersive experiences. Located in the Main Hall.

---

## Content Items (Layer 2)

### Category: Paintings

#### Echoes of Tomorrow

**Artist:** Maya Chen
**Year:** 2024
**Medium:** Oil on canvas, LED elements
**Dimensions:** 180 × 240 cm

A stunning fusion of traditional oil painting with embedded LED lighting, this piece depicts a cityscape that shifts between day and night. Chen explores how technology shapes our perception of urban spaces and the passage of time.

*"I wanted to capture that moment between waking and dreaming, when the city exists in both states simultaneously."* — Maya Chen

**AI Knowledge:** Maya Chen (b. 1988, Taipei) is a Taiwanese-American artist known for incorporating technology into traditional painting. Studied at RISD and Central Saint Martins. This piece took 8 months to complete.

---

#### Concrete Dreams

**Artist:** Fatima Al-Hassan
**Year:** 2024
**Medium:** Concrete, embedded photographs, resin
**Dimensions:** 90 × 120 cm (triptych)

A triptych embedding family photographs within concrete slabs, exploring themes of memory, permanence, and the built environment.

**AI Knowledge:** Fatima Al-Hassan (b. 1985, Beirut) explores memory and displacement. Uses actual family photographs from her grandmother's collection.

---

### Category: Sculptures

#### Fragments of Self

**Artist:** James Okonkwo
**Year:** 2023
**Medium:** Recycled mirrors, steel frame
**Dimensions:** 200 × 150 × 150 cm

A sculptural installation using 847 recycled mirror fragments arranged to create a fragmented human figure.

**AI Knowledge:** James Okonkwo (b. 1975, Lagos) explores identity and diaspora through sculpture. Winner of the Turner Prize 2023.

---

#### The Weight of Water

**Artist:** David Park
**Year:** 2023
**Medium:** Cast glass, suspended steel cables
**Dimensions:** 400 × 300 × 250 cm

Twelve thousand hand-cast glass droplets suspended from the ceiling, creating an ethereal rain frozen in time.

**AI Knowledge:** David Park (b. 1980, Seoul) is known for large-scale glass installations. Each droplet was individually cast over 18 months.

---

### Category: Digital Art

#### Digital Garden #7

**Artist:** Sofia Andersson
**Year:** 2024
**Medium:** Generative AI, projection mapping
**Dimensions:** Variable (room-scale installation)

An immersive digital environment where AI-generated flowers bloom and wilt in response to viewers' movements.

**AI Knowledge:** Sofia Andersson (b. 1992, Stockholm) specializes in AI-generated art. Each viewing experience is unique.

---

### Category: Installations

#### Woven Histories

**Artist:** Amara Diallo
**Year:** 2023
**Medium:** Reclaimed textiles, gold thread
**Dimensions:** 500 × 300 cm

A monumental tapestry created from clothing donated by immigrant families, stitched together with gold thread that traces migration routes.

**AI Knowledge:** Amara Diallo (b. 1983, Dakar) specializes in textile art addressing migration. Contains fabric from over 200 families across 5 continents.

---

## Notes

- **Grid layout**: 2 columns on mobile, 3-4 on larger screens
- **Grouped by medium**: Helps visitors navigate by art type
- **AI provides context**: Artist backgrounds, techniques, exhibition info
- **Images recommended**: High-quality photos of each artwork enhance the gallery experience
